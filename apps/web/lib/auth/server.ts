import { redirect } from 'next/navigation';
import type { Role } from './roles';
import { createServerClientInstance } from '@/lib/supabase/server';

export type Membership = {
  organization_id: string;
  role: Role;
  status: 'active';
};

const validRoles: Role[] = ['manager', 'teacher', 'student', 'sales'];

export async function getCurrentMembership(): Promise<Membership | null> {
  const supabase = createServerClientInstance();
  const { data: { user }, error: userError } = await supabase.auth.getUser();
  if (userError || !user) return null;

  const { data, error } = await supabase.rpc('get_current_memberships');
  if (error || !Array.isArray(data)) return null;

  const memberships = data.filter((item: any) =>
    typeof item.organization_id === 'string' &&
    validRoles.includes(item.role) &&
    item.status === 'active'
  ) as Membership[];

  // Until an organization switcher exists, fail closed for multi-organization users.
  if (memberships.length !== 1) return null;
  return memberships[0];
}

export async function requireRole(allowedRoles: Role[]) {
  const membership = await getCurrentMembership();
  if (!membership) redirect('/login?error=membership');
  if (!allowedRoles.includes(membership.role)) redirect('/dashboard?error=forbidden');
  return membership;
}
