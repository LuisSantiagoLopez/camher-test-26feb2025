import { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import { Upload, FileText, Check, X } from 'lucide-react';
import { Part } from '../../types';
import toast from 'react-hot-toast';
import PartDetailsModal from '../../components/modals/PartDetailsModal';
import ProviderVerification from '../../components/ProviderVerification';
import { useAuthStore } from '../../store/authStore';

export default function ProveedorDashboard() {
  const [parts, setParts] = useState<Part[]>([]);
  const [loading, setLoading] = useState(true);
  const [uploadingInvoice, setUploadingInvoice] = useState<string | null>(null);
  const [selectedPart, setSelectedPart] = useState<Part | null>(null);
  const { profile } = useAuthStore();

  useEffect(() => {
    fetchParts();
  }, []);

  const fetchParts = async () => {
    try {
      // Obtener el ID del proveedor basado en el email del perfil
      const { data: providerData, error: providerError } = await supabase
        .from('providers')
        .select('id')
        .eq('email', profile?.email)
        .single();

      if (providerError) throw providerError;

      // Obtener solo las refacciones asignadas a este proveedor
      const { data, error } = await supabase
        .from('parts')
        .select(`
          *,
          unit:units(name)
        `)
        .eq('provider_id', providerData.id) // Filtrar por provider_id
        .in('status', [3, 4, 5, 6])
        .order('created_at', { ascending: false });

      if (error) throw error;
      setParts(data || []);
    } catch (error: any) {
      toast.error('Error al cargar refacciones');
    } finally {
      setLoading(false);
    }
  };

  const handleAcceptPart = async (partId: string) => {
    try {
      console.log('Attempting to update part:', partId);
      
      const { error } = await supabase
        .from('parts')
        .update({ status: 4 })
        .eq('id', partId);

      if (error) {
        console.error('Update error:', error);
        throw error;
      }
      
      toast.success('Refacción aceptada');
      fetchParts();
    } catch (error: any) {
      console.error('Full error:', error);
      toast.error(`Error al aceptar refacción: ${error.message}`);
    }
  };

  const handleRejectPart = async (partId: string) => {
    if (!confirm('¿Estás seguro de rechazar esta refacción? La refacción volverá al taller para su revisión.')) return;

    try {
      const { error } = await supabase
        .from('parts')
        .update({ status: 0 })
        .eq('id', partId);

      if (error) throw error;
      
      toast.success('Refacción devuelta al taller para revisión');
      fetchParts();
    } catch (error: any) {
      console.error('Error rejecting part:', error);
      toast.error(`Error al rechazar refacción: ${error.message}`);
    }
  };

  const handleUploadInvoice = async (partId: string, file: File) => {
    setUploadingInvoice(partId);

    try {
      const fileExt = file.name.split('.').pop();
      const filePath = `${partId}/invoice.${fileExt}`;

      const { error: uploadError } = await supabase.storage
        .from('part_files')
        .upload(filePath, file);

      if (uploadError) throw uploadError;

      const { error: fileError } = await supabase
        .from('part_files')
        .insert({
          part_id: partId,
          file_type: 'invoice',
          file_path: filePath,
        });

      if (fileError) throw fileError;

      const { error: partError } = await supabase
        .from('parts')
        .update({ status: 5 })
        .eq('id', partId);

      if (partError) throw partError;

      toast.success('Factura subida exitosamente');
      fetchParts();
    } catch (error: any) {
      toast.error('Error al subir factura');
    } finally {
      setUploadingInvoice(null);
    }
  };

  const getStatusBadgeColor = (status: number) => {
    switch (status) {
      case 3: return 'bg-yellow-100 text-yellow-800';
      case 4: return 'bg-blue-100 text-blue-800';
      case 5: return 'bg-purple-100 text-purple-800';
      case 6: return 'bg-green-100 text-green-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusText = (status: number) => {
    switch (status) {
      case 3: return 'Pendiente de revisión';
      case 4: return 'Esperando factura';
      case 5: return 'Esperando contrarecibo';
      case 6: return 'Completada';
      default: return 'Desconocido';
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Gestión de Refacciones</h1>

      <div className="bg-white shadow overflow-hidden sm:rounded-lg">
        <ul className="divide-y divide-gray-200">
          {parts.map((part) => (
            <ProviderVerification key={part.id} providerId={part.provider_id}>
              <li className="px-6 py-4">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <div className="flex items-center space-x-3">
                      <p className="text-sm font-medium text-gray-900">
                        {part.description?.[0]}
                      </p>
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusBadgeColor(part.status)}`}>
                        {getStatusText(part.status)}
                      </span>
                    </div>
                    <div className="mt-2 flex items-center text-sm text-gray-500 space-x-4">
                      <span>Unidad: {part.unit?.name}</span>
                      <span>Precio: ${part.price}</span>
                      <span>Tipo: {part.is_cash ? 'Efectivo' : 'Transferencia'}</span>
                    </div>
                  </div>
                  <div className="flex items-center space-x-4">
                    {part.status === 3 && (
                      <>
                        <button
                          onClick={() => handleAcceptPart(part.id)}
                          className="text-green-600 hover:text-green-700"
                          title="Aceptar refacción"
                        >
                          <Check className="h-5 w-5" />
                        </button>
                        <button
                          onClick={() => handleRejectPart(part.id)}
                          className="text-red-600 hover:text-red-700"
                          title="Rechazar refacción"
                        >
                          <X className="h-5 w-5" />
                        </button>
                      </>
                    )}
                    {part.status === 4 && (
                      <div className="relative">
                        <input
                          type="file"
                          accept=".pdf,.jpg,.jpeg,.png"
                          onChange={(e) => {
                            const file = e.target.files?.[0];
                            if (file) handleUploadInvoice(part.id, file);
                          }}
                          className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                          disabled={uploadingInvoice === part.id}
                        />
                        <button
                          className={`text-blue-600 hover:text-blue-700 ${
                            uploadingInvoice === part.id ? 'opacity-50 cursor-not-allowed' : ''
                          }`}
                          title="Subir factura"
                        >
                          <Upload className="h-5 w-5" />
                        </button>
                      </div>
                    )}
                    <button
                      onClick={() => setSelectedPart(part)}
                      className="text-blue-600 hover:text-blue-700"
                      title="Ver detalles"
                    >
                      <FileText className="h-5 w-5" />
                    </button>
                  </div>
                </div>
              </li>
            </ProviderVerification>
          ))}
          {parts.length === 0 && (
            <li className="px-6 py-12 text-center text-gray-500">
              No hay refacciones asignadas
            </li>
          )}
        </ul>
      </div>

      {selectedPart && (
        <PartDetailsModal
          part={selectedPart}
          onClose={() => setSelectedPart(null)}
        />
      )}
    </div>
  );
}