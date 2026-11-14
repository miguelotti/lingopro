'use client';

import { useActionState } from 'react';
import { createLead, type CreateLeadState } from './actions';

const initialState: CreateLeadState = {};

export function LeadForm() {
  const [state, action, pending] = useActionState(createLead, initialState);
  return (
    <form action={action} className="lead-form">
      <label>Nome do aluno *<input name="student_name" required maxLength={160} /></label>
      <label>Idade<input name="student_age" type="number" min="0" max="120" /></label>
      <label>Curso de interesse<input name="course_interest" maxLength={160} /></label>
      <label>Nome do responsável<input name="guardian_name" maxLength={160} /></label>
      <label>Telefone / WhatsApp do responsável *<input name="guardian_phone" type="tel" required maxLength={32} /></label>
      <label>E-mail<input name="email" type="email" maxLength={254} /></label>
      <label>Origem<select name="source" defaultValue="manual"><option value="manual">Manual</option><option value="indication">Indicação</option><option value="instagram">Instagram</option><option value="website">Site</option><option value="whatsapp">WhatsApp</option><option value="other">Outra</option></select></label>
      {state.error && <p className="form-message error" role="alert">{state.error}</p>}
      {state.success && <p className="form-message success" role="status">{state.success}</p>}
      <button className="button-primary" disabled={pending}>{pending ? 'Salvando…' : 'Cadastrar lead'}</button>
    </form>
  );
}
