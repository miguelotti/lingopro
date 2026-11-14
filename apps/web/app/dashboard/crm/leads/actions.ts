'use server';

import { revalidatePath } from 'next/cache';
import { getCurrentMembership } from '@/lib/auth/server';
import { createServerClientInstance } from '@/lib/supabase/server';

export type CreateLeadState = { error?: string; success?: string };

export async function createLead(_previousState: CreateLeadState, formData: FormData): Promise<CreateLeadState> {
  const membership = await getCurrentMembership();
  if (!membership || !['manager', 'sales'].includes(membership.role)) {
    return { error: 'Você não tem permissão para cadastrar leads.' };
  }

  const studentName = String(formData.get('student_name') ?? '').trim();
  const phone = String(formData.get('guardian_phone') ?? '').trim();
  const ageValue = String(formData.get('student_age') ?? '').trim();
  const age = ageValue ? Number(ageValue) : null;

  if (!studentName || !phone) return { error: 'Nome do aluno e telefone do responsável são obrigatórios.' };
  if (age !== null && (!Number.isInteger(age) || age < 0 || age > 120)) return { error: 'Informe uma idade válida.' };

  const supabase = createServerClientInstance();
  const { data: stage, error: stageError } = await supabase
    .from('kanban_stages')
    .select('id')
    .eq('organization_id', membership.organization_id)
    .eq('stage_key', 'new')
    .eq('is_active', true)
    .maybeSingle();

  if (stageError || !stage) return { error: 'A etapa inicial do CRM não está configurada. Peça ao gestor para verificar as migrações.' };

  const { error } = await supabase.rpc('create_lead_with_history', {
    p_organization_id: membership.organization_id,
    p_stage_id: stage.id,
    p_student_name: studentName,
    p_student_age: age,
    p_course_interest: String(formData.get('course_interest') ?? '').trim() || null,
    p_guardian_name: String(formData.get('guardian_name') ?? '').trim() || null,
    p_guardian_phone: phone,
    p_email: String(formData.get('email') ?? '').trim() || null,
    p_source: String(formData.get('source') ?? 'manual').trim() || 'manual'
  });

  if (error) return { error: 'Não foi possível salvar o lead. Verifique os dados e tente novamente.' };
  revalidatePath('/dashboard/crm');
  revalidatePath('/dashboard/crm/leads');
  return { success: 'Lead cadastrado com sucesso.' };
}
