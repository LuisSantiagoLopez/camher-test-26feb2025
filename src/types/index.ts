export type UserRole = 'taller' | 'admin' | 'proveedor' | 'contador';

export interface Profile {
  id: string;
  user_id: string;
  role: UserRole;
  name: string;
  email: string;
  is_approved: boolean;
  created_at: string;
}

export interface Part {
  id: string;
  unit_id: string;
  provider_id: string | null;
  status: number;
  description: string[];
  price: number;
  unitary_price: number[];
  quantity: number[];
  is_cash: boolean;
  is_important: boolean;
  disposal_location: string;
  failure_report: {
    problemLocation: string;
    operator: string;
    description: string;
  };
  work_order: {
    jobToBeDone: string;
    personInCharge: string;
    sparePart: string;
    observation: string;
  };
  mechanic_review: {
    mechanic: string;
  };
  invoice_info: {
    subTotal: number;
    date: string;
    number: string;
  };
  req_date: string;
  created_at: string;
  unit?: Unit;
  provider?: Provider;
  files?: PartFile[];
}

export interface Unit {
  id: string;
  name: string;
  created_at: string;
}

export interface Provider {
  id: string;
  name: string;
  email: string;
  created_at: string;
}

export interface PartFile {
  id: string;
  part_id: string;
  file_type: 'accident_proof' | 'invoice' | 'counter_receipt';
  file_path: string;
  created_at: string;
}

export interface EmailNotification {
  id: string;
  part_id: string;
  recipient: string;
  type: 'verification' | 'provider_review' | 'admin_review' | 'contador_receipt';
  status: 'sent' | 'failed';
  created_at: string;
  error?: string;
  part?: Part;
}