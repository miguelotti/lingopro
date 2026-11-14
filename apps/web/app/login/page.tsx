"use client";

import { useRouter } from 'next/navigation';
import { FormEvent, useState } from 'react';
import { createClient } from '@/lib/supabase/client';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    const supabase = createClient();

    const { error } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (error) {
      setError(error.message);
      return;
    }

    router.push('/dashboard');
    router.refresh();
  };

  return (
    <main style={{ maxWidth: 420, margin: '4rem auto', padding: '2rem', borderRadius: 16, background: '#fff' }}>
      <h1 style={{ marginTop: 0 }}>LingoPro Login</h1>

      <form onSubmit={handleSubmit} style={{ display: 'grid', gap: '1rem' }}>
        <label>
          E-mail
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            style={{ width: '100%', padding: '0.75rem', marginTop: '0.5rem' }}
            required
          />
        </label>

        <label>
          Senha
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            style={{ width: '100%', padding: '0.75rem', marginTop: '0.5rem' }}
            required
          />
        </label>

        {error && <p style={{ color: 'crimson' }}>{error}</p>}

        <button type="submit" style={{ padding: '0.8rem 1rem', cursor: 'pointer' }}>
          Entrar
        </button>
      </form>
    </main>
  );
}
