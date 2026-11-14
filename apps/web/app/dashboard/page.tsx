import { redirect } from 'next/navigation';
import { createServerClientInstance } from '@/lib/supabase/server';

export default async function DashboardPage() {
  const supabase = createServerClientInstance();
  const { data, error } = await supabase.auth.getUser();

  if (error || !data.user) {
    redirect('/login');
  }

  return (
    <main style={{ padding: '2rem', maxWidth: 960, margin: '0 auto' }}>
      <h1>LingoPro Dashboard</h1>
      <p>Bem-vindo(a), {data.user.email}</p>

      <div style={{ display: 'grid', gap: '1rem', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))' }}>
        <section style={{ background: '#fff', padding: '1rem 1.25rem', borderRadius: 12 }}>
          <h3>CRM</h3>
          <p>Leads, pipelines e SLA.</p>
        </section>

        <section style={{ background: '#fff', padding: '1rem 1.25rem', borderRadius: 12 }}>
          <h3>LMS</h3>
          <p>Aulas, conteúdos e avaliações.</p>
        </section>

        <section style={{ background: '#fff', padding: '1rem 1.25rem', borderRadius: 12 }}>
          <h3>Operação</h3>
          <p>Dashboards e integrações.</p>
        </section>
      </div>
    </main>
  );
}
