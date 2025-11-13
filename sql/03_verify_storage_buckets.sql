-- =============================================
-- VERIFICACIÓN Y CREACIÓN DE STORAGE BUCKETS
-- =============================================
-- Ejecutar después de 00_CONSOLIDATED_SCHEMA.sql
-- Este script verifica y crea los buckets de almacenamiento
-- necesarios para fotos de asistencia y perfiles

-- =============================================
-- PASO 1: VERIFICAR BUCKETS EXISTENTES
-- =============================================

-- Ejecuta este query para ver buckets actuales
SELECT id, name, public, created_at
FROM storage.buckets
ORDER BY name;

-- =============================================
-- PASO 2: CREAR BUCKETS SI NO EXISTEN
-- =============================================

-- Crear bucket para fotos de asistencia
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'attendance-photos',
    'attendance-photos',
    true,  -- Acceso público de lectura
    5242880,  -- 5MB límite por archivo
    ARRAY['image/jpeg', 'image/png', 'image/jpg', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
SET 
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/jpg', 'image/webp'];

-- Crear bucket para fotos de perfil
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profile-photos',
    'profile-photos',
    true,  -- Acceso público de lectura
    2097152,  -- 2MB límite por archivo
    ARRAY['image/jpeg', 'image/png', 'image/jpg', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
SET 
    public = true,
    file_size_limit = 2097152,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/jpg', 'image/webp'];

-- =============================================
-- PASO 3: POLÍTICAS DE SEGURIDAD PARA STORAGE
-- =============================================

-- Limpiar políticas existentes
DROP POLICY IF EXISTS "Users can upload their attendance photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can view attendance photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their attendance photos" ON storage.objects;
DROP POLICY IF EXISTS "Managers can delete attendance photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can view profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their profile photos" ON storage.objects;

-- =============================================
-- POLÍTICAS PARA ATTENDANCE-PHOTOS
-- =============================================

-- Usuarios autenticados pueden subir sus propias fotos de asistencia
CREATE POLICY "Users can upload their attendance photos"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
      bucket_id = 'attendance-photos'
      AND owner = auth.uid()
    );

-- Cualquier usuario autenticado puede ver fotos de asistencia
CREATE POLICY "Users can view attendance photos"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'attendance-photos');

-- Solo managers pueden eliminar fotos de asistencia
CREATE POLICY "Managers can delete attendance photos"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
      bucket_id = 'attendance-photos'
      AND auth.uid() IN (SELECT id FROM public.users WHERE role = 'manager')
    );

-- =============================================
-- POLÍTICAS PARA PROFILE-PHOTOS
-- =============================================

-- Usuarios pueden subir su propia foto de perfil
CREATE POLICY "Users can upload their profile photos"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
      bucket_id = 'profile-photos'
      AND owner = auth.uid()
    );

-- Usuarios pueden actualizar su propia foto de perfil
CREATE POLICY "Users can update their profile photos"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
      bucket_id = 'profile-photos'
      AND owner = auth.uid()
    )
    WITH CHECK (
      bucket_id = 'profile-photos'
      AND owner = auth.uid()
    );

-- Cualquier usuario autenticado puede ver fotos de perfil
CREATE POLICY "Users can view profile photos"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'profile-photos');

-- Usuarios pueden eliminar su propia foto de perfil
CREATE POLICY "Users can delete their profile photos"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
      bucket_id = 'profile-photos'
      AND owner = auth.uid()
    );

-- =============================================
-- PASO 4: VERIFICAR CONFIGURACIÓN
-- =============================================

-- Ver buckets configurados
SELECT 
    id,
    name,
    public,
    file_size_limit / 1048576.0 AS max_size_mb,
    allowed_mime_types,
    created_at
FROM storage.buckets
WHERE id IN ('attendance-photos', 'profile-photos')
ORDER BY name;

-- Ver políticas de storage
SELECT 
    policyname,
    tablename,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'objects'
AND schemaname = 'storage'
ORDER BY policyname;

-- =============================================
-- RESULTADO ESPERADO
-- =============================================

/*
BUCKETS CREADOS:
┌──────────────────────┬───────┬────────────┬─────────────────────────┐
│ id                   │ public│ max_size_mb│ allowed_mime_types      │
├──────────────────────┼───────┼────────────┼─────────────────────────┤
│ attendance-photos    │ true  │ 5.00       │ {image/jpeg, image/png} │
│ profile-photos       │ true  │ 2.00       │ {image/jpeg, image/png} │
└──────────────────────┴───────┴────────────┴─────────────────────────┘

POLÍTICAS CREADAS:
- Users can upload their attendance photos (INSERT)
- Users can view attendance photos (SELECT)
- Managers can delete attendance photos (DELETE)
- Users can upload their profile photos (INSERT)
- Users can update their profile photos (UPDATE)
- Users can view profile photos (SELECT)
- Users can delete their profile photos (DELETE)
*/

-- =============================================
-- MENSAJE DE CONFIRMACIÓN
-- =============================================

DO $$ 
BEGIN 
    RAISE NOTICE '✅ Storage buckets verificados y configurados exitosamente';
    RAISE NOTICE '📸 attendance-photos: 5MB max, formatos: JPEG, PNG, JPG, WebP';
    RAISE NOTICE '👤 profile-photos: 2MB max, formatos: JPEG, PNG, JPG, WebP';
    RAISE NOTICE '🔒 Políticas de seguridad aplicadas correctamente';
END $$;
