import { redirect } from 'next/navigation';
import type { ReactNode } from 'react';
import { getCurrentMembership } from '@/lib/auth/server';
import { ROLE_LABELS, type Role } from '@/lib/auth/roles';

const NAV_ITEMS: Record<Role, { label: string; href: string }[]> = {
  manager: [
    { label: 'Painel', href: '/dashboard' },
    { label: 'CRM', href: '/dashboard/crm' },
    { label: 'LMS', href: '/dashboard/lms' },
    { label: 'Administração', href: '/dashboard/admin' }
  ],
  teacher: [
    { label: 'Painel', href: '/dashboard' },
    { label: 'LMS', href: '/dashboard/lms' },
    { label: 'Aulas', href: '/dashboard/lms/classes' }
  ],
  student: [
    { label: 'Painel', href: '/dashboard' },
    { label: 'Meus cursos', href: '/dashboard/lms' },
    { label: 'Aulas', href: '/dashboard/lms/classes' }
  ],
  sales: [
    { label: 'Painel', href: '/dashboard' },
    { label: 'CRM', href: '/dashboard/crm' },
    { label: 'Leads', href: '/dashboard/crm/leads' }
  ]
};

export default async function DashboardLayout({ children }: { children: ReactNode }) {
  const membership = await getCurrentMembership();
  if (!membership) redirect('/login?error=membership');
  const navItems = NAV_ITEMS[membership.role];

  return (
    <div className="app-shell">
      <header className="app-header">
        <a className="brand" href="/dashboard">LingoPro</a>
        <span className="role-badge">{ROLE_LABELS[membership.role]}</span>
      </header>
      <nav className="app-nav" aria-label="Navegação principal">
        {navItems.map((item) => <a key={item.href} href={item.href}>{item.label}</a>)}
      </nav>
      <main className="app-main">{children}</main>
    </div>
  );
}
