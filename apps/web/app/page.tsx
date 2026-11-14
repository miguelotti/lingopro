export default function HomePage() {
  return (
    <main style={{ padding: '2rem', fontFamily: 'sans-serif' }}>
      <h1>LingoPro</h1>
      <p>CRM + LMS para operação comercial e pedagógica.</p>
      <p>Este é o scaffold inicial com autenticação e rotas protegidas preparadas para Supabase.</p>

      <div style={{ display: 'flex', gap: '1rem', marginTop: '1.5rem', flexWrap: 'wrap' }}>
        <a href="/login" style={{ padding: '0.75rem 1rem', background: '#111827', color: '#fff', borderRadius: 8, textDecoration: 'none' }}>
          Login
        </a>
        <a href="/dashboard" style={{ padding: '0.75rem 1rem', background: '#e5e7eb', color: '#111827', borderRadius: 8, textDecoration: 'none' }}>
          Dashboard
        </a>
      </div>
    </main>
  );
}
