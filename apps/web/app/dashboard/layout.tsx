import { redirect } from 'next/navigation';
import type { ReactNode } from 'react';
import { createServerClientInstance } from '@/lib/supabase/server';
import { getRoleFromUser, ROLE_LABELS, type Role } from '@/lib/auth/roles';

const NAV_ITEMS: Record<Role, { label: string; href: string }[]> = {
  manager: [
    { label: 'Dashboard', href: '/dashboard' },
    { label: 'CRM', href: '/dashboard/crm' },
    { label: 'LMS', href: '/dashboard/lms' },
    { label: 'Admin', href: '/dashboard/admin' }
  ],
  teacher: [
    { label: 'Dashboard', href: '/dashboard' },
    { label: 'LMS', href: '/dashboard/lms' },
    { label: 'Aulas', href: '/dashboard/lms/classes' }
  ],
  student: [
    { label: 'Dashboard', href: '/dashboard' },
    { label: 'Curso', href: '/dashboard/lms' },
    { label: 'Aulas', href: '/dashboard/lms/classes' }
  ],
  sales: [
    { label: 'Dashboard', href: '/dashboard' },
    { label: 'CRM', href: '/dashboard/crm' },
    { label: 'Leads', href: '/dashboard/crm/leads' }
  ]
};

export default async function DashboardLayout({ children }: { children: ReactNode }) {
  const supabase = createServerClientInstance();
  const { data, error } = await supabase.auth.getUser();

  if (error || !data.user) {
    redirect('/login');
  }

  const userRole = getRoleFromUser(data.user) ?? 'student';
  const navItems = NAV_ITEMS[userRole] ?? NAV_ITEMS.student;

  return (
    <div style={{ minHeight: '100vh', background: '#f3f4f6' }}>
      <header
        style={{
          background: '#111827',
          color: 'white',
          padding: '1rem 2rem',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center'
        }}
      >
        <strong>LingoPro</strong>
        <span>{ROLE_LABELS[userRole]}</span>
      </header>

      <nav
        style={{
          background: '#fff',
          borderBottom: '1px solid #e5e7eb',
          padding: '0.75rem 2rem',
          display: 'flex',
          gap: '1rem',
          flexWrap: 'wrap'
        }}
      >
        {navItems.map((item) => (
          <a
            key={item.href}
            href={item.href}
            style={{ color: '#111827', textDecoration: 'none', fontWeight: 600 }}
          >
            {item.label}
          </a>
        ))}
      </nav>

      <main style={{ padding: '2rem' }}>{children}</main>
    </div>
  );
}
