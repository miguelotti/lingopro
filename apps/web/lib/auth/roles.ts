import type { User } from '@supabase/supabase-js';

export const ROLES = ['manager', 'teacher', 'student', 'sales'] as const;
export type Role = (typeof ROLES)[number];

export const ROLE_LABELS: Record<Role, string> = {
  manager: 'Gestor',
  teacher: 'Professor',
  student: 'Aluno',
  sales: 'Comercial'
};

export function getRoleFromUser(user: User | null): Role | null {
  const rawRole = user?.user_metadata?.role ?? user?.app_metadata?.role;

  if (typeof rawRole !== 'string') {
    return null;
  }

  const normalized = rawRole.toLowerCase();
  return ROLES.includes(normalized as Role) ? (normalized as Role) : null;
}

export function getOrganizationIdFromUser(user: User | null): string | null {
  const rawOrgId = user?.user_metadata?.organization_id ?? user?.app_metadata?.organization_id;
  return typeof rawOrgId === 'string' ? rawOrgId : null;
}

export function canAccessRole(user: User | null, allowedRoles: Role[]) {
  const userRole = getRoleFromUser(user);
  return !!userRole && allowedRoles.includes(userRole);
}
