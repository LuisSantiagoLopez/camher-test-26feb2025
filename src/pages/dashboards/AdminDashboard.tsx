import { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import { Check, X, FileText } from 'lucide-react';
import { Profile, Part } from '../../types';
import toast from 'react-hot-toast';
import PartDetailsModal from '../../components/modals/PartDetailsModal';
import PartProgressBar from '../../components/PartProgressBar';

interface PartHistory {
  old_status: number;
  new_status: number;
  changed_at: string;
}

export default function AdminDashboard() {
  const [pendingUsers, setPendingUsers] = useState<Profile[]>([]);
  const [parts, setParts] = useState<Part[]>([]);
  const [partHistories, setPartHistories] = useState<Record<string, PartHistory[]>>({});
  const [loading, setLoading] = useState(true);
  const [selectedPart, setSelectedPart] = useState<Part | null>(null);

  useEffect(() => {
    fetchPendingUsers();
    fetchParts();
  }, []);

  const fetchPendingUsers = async () => {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('is_approved', false)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setPendingUsers(data || []);
    } catch (error: any) {
      toast.error('Error al cargar usuarios pendientes');
    }
  };

  const fetchParts = async () => {
    try {
      const { data, error } = await supabase
        .from('parts')
        .select(`
          *,
          unit:units(name),
          provider:providers(name),
          files:part_files(file_type)
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setParts(data || []);

      // Fetch history for each part
      const histories: Record<string, PartHistory[]> = {};
      for (const part of data || []) {
        const { data: historyData, error: historyError } = await supabase
          .from('part_history')
          .select('old_status, new_status, changed_at')
          .eq('part_id', part.id)
          .order('changed_at', { ascending: true });

        if (historyError) throw historyError;
        histories[part.id] = historyData || [];
      }
      setPartHistories(histories);
    } catch (error: any) {
      toast.error('Error al cargar refacciones');
    } finally {
      setLoading(false);
    }
  };

  const handleApproveUser = async (userId: string) => {
    try {
      const { error } = await supabase
        .from('profiles')
        .update({ is_approved: true })
        .eq('user_id', userId);

      if (error) throw error;
      
      toast.success('Usuario aprobado');
      fetchPendingUsers();
    } catch (error: any) {
      toast.error('Error al aprobar usuario');
    }
  };

  const handleRejectUser = async (userId: string) => {
    if (!confirm('¿Estás seguro de rechazar este usuario?')) return;

    try {
      const { error } = await supabase
        .from('profiles')
        .delete()
        .eq('user_id', userId);

      if (error) throw error;
      
      toast.success('Usuario rechazado');
      fetchPendingUsers();
    } catch (error: any) {
      toast.error('Error al rechazar usuario');
    }
  };

  const handleApprovePart = async (partId: string) => {
    try {
      const { error } = await supabase
        .from('parts')
        .update({ status: 3 })
        .eq('id', partId);

      if (error) throw error;
      
      toast.success('Refacción aprobada');
      fetchParts();
    } catch (error: any) {
      console.error('Error approving part:', error);
      toast.error('Error al aprobar refacción: ' + error.message);
    }
  };

  const handleRejectPart = async (partId: string) => {
    if (!confirm('¿Estás seguro de rechazar esta refacción? La refacción volverá al taller para su revisión.')) return;

    try {
      const { error } = await supabase
        .from('parts')
        .update({ status: 0 }) // Cambio a estado 0 para que el taller pueda editarla
        .eq('id', partId);

      if (error) throw error;
      
      toast.success('Refacción devuelta al taller para revisión');
      fetchParts();
    } catch (error: any) {
      console.error('Error rejecting part:', error);
      toast.error('Error al rechazar refacción: ' + error.message);
    }
  };

  const getStatusBadgeColor = (status: number) => {
    switch (status) {
      case -1: return 'bg-red-100 text-red-800';
      case 0: return 'bg-gray-100 text-gray-800';
      case 1: return 'bg-blue-100 text-blue-800';
      case 2: return 'bg-yellow-100 text-yellow-800';
      case 3: return 'bg-purple-100 text-purple-800';
      case 4: return 'bg-green-100 text-green-800';
      case 5: return 'bg-pink-100 text-pink-800';
      case 6: return 'bg-emerald-100 text-emerald-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusText = (status: number) => {
    switch (status) {
      case -1: return 'Cancelada';
      case 0: return 'No creada';
      case 1: return 'Creada';
      case 2: return 'En revisión (Admin)';
      case 3: return 'En revisión (Proveedor)';
      case 4: return 'Esperando factura';
      case 5: return 'Esperando contrarecibo';
      case 6: return 'Completada';
      default: return 'Desconocido';
    }
  };

  const hasCounterReceipt = (part: Part) => {
    return part.files?.some(file => file.file_type === 'counter_receipt');
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500" />
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <section>
        <h2 className="text-2xl font-bold text-gray-900 mb-4">Usuarios Pendientes de Aprobación</h2>
        <div className="bg-white shadow overflow-hidden sm:rounded-lg">
          <ul className="divide-y divide-gray-200">
            {pendingUsers.map((user) => (
              <li key={user.id} className="px-6 py-4">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-gray-900">{user.name}</p>
                    <p className="text-sm text-gray-500">{user.email}</p>
                    <p className="text-sm text-gray-500">Rol: {user.role}</p>
                  </div>
                  <div className="flex items-center space-x-4">
                    <button
                      onClick={() => handleApproveUser(user.user_id)}
                      className="text-green-600 hover:text-green-700"
                    >
                      <Check className="h-5 w-5" />
                    </button>
                    <button
                      onClick={() => handleRejectUser(user.user_id)}
                      className="text-red-600 hover:text-red-700"
                    >
                      <X className="h-5 w-5" />
                    </button>
                  </div>
                </div>
              </li>
            ))}
            {pendingUsers.length === 0 && (
              <li className="px-6 py-12 text-center text-gray-500">
                No hay usuarios pendientes de aprobación
              </li>
            )}
          </ul>
        </div>
      </section>

      <section>
        <h2 className="text-2xl font-bold text-gray-900 mb-4">Seguimiento de Refacciones</h2>
        <div className="bg-white shadow overflow-hidden sm:rounded-lg">
          <ul className="divide-y divide-gray-200">
            {parts.map((part) => (
              <li key={part.id} className="px-6 py-6">
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <div className="flex-1">
                      <div className="flex items-center space-x-3">
                        <p className="text-sm font-medium text-gray-900">
                          {part.description?.[0]}
                        </p>
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusBadgeColor(part.status)}`}>
                          {getStatusText(part.status)}
                        </span>
                        {part.status === 5 && !hasCounterReceipt(part) && (
                          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                            Pendiente contrarecibo
                          </span>
                        )}
                      </div>
                      <div className="mt-2 flex items-center text-sm text-gray-500 space-x-4">
                        <span>Unidad: {part.unit?.name}</span>
                        <span>Precio: ${part.price}</span>
                        <span>Tipo: {part.is_cash ? 'Efectivo' : 'Transferencia'}</span>
                      </div>
                    </div>
                    <div className="flex items-center space-x-4">
                      {part.status === 2 && (
                        <>
                          <button
                            onClick={() => handleApprovePart(part.id)}
                            className="text-green-600 hover:text-green-700"
                          >
                            <Check className="h-5 w-5" />
                          </button>
                          <button
                            onClick={() => handleRejectPart(part.id)}
                            className="text-red-600 hover:text-red-700"
                          >
                            <X className="h-5 w-5" />
                          </button>
                        </>
                      )}
                      <button
                        onClick={() => setSelectedPart(part)}
                        className="text-blue-600 hover:text-blue-700 ml-4 cursor-pointer"
                      >
                        <FileText className="h-5 w-5" />
                      </button>
                    </div>
                  </div>

                  <div className="pt-4">
                    <PartProgressBar
                      status={part.status}
                      history={partHistories[part.id]}
                    />
                  </div>
                </div>
              </li>
            ))}
            {parts.length === 0 && (
              <li className="px-6 py-12 text-center text-gray-500">
                No hay refacciones registradas
              </li>
            )}
          </ul>
        </div>
      </section>

      {selectedPart && (
        <PartDetailsModal
          part={selectedPart}
          onClose={() => setSelectedPart(null)}
        />
      )}
    </div>
  );
}