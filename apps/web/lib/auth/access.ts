import type { User } from '@supabase/supabase-js';
import { canAccessRole, type Role } from '@/lib/auth/roles';

export function hasDashboardPermission(
  user: User | null,
  allowedRoles: Role[] = ['manager', 'teacher', 'student', 'sales']
) {
  return canAccessRole(user, allowedRoles);
}

export function buildAccessMessage(user: User | null) {
  const role = user?.user_metadata?.role ?? user?.app_metadata?.role;
  return typeof role === 'string' ? `Perfil atual: ${role}` : 'Perfil não informado';
}
