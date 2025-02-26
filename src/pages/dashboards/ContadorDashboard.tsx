import { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import { Upload, FileText } from 'lucide-react';
import { Part } from '../../types';
import toast from 'react-hot-toast';
import PartDetailsModal from '../../components/modals/PartDetailsModal';

export default function ContadorDashboard() {
  const [parts, setParts] = useState<Part[]>([]);
  const [loading, setLoading] = useState(true);
  const [uploadingReceipt, setUploadingReceipt] = useState<string | null>(null);
  const [selectedPart, setSelectedPart] = useState<Part | null>(null);

  useEffect(() => {
    fetchParts();
  }, []);

  const fetchParts = async () => {
    try {
      const { data, error } = await supabase
        .from('parts')
        .select(`
          *,
          unit:units(name),
          provider:providers(name)
        `)
        .in('status', [4, 5, 6])
        .order('created_at', { ascending: false });

      if (error) throw error;
      setParts(data || []);
    } catch (error: any) {
      console.error('Error fetching parts:', error);
      toast.error('Error al cargar refacciones');
    } finally {
      setLoading(false);
    }
  };

  const handleUploadReceipt = async (partId: string, file: File) => {
    setUploadingReceipt(partId);
    console.log('Starting receipt upload for part:', partId);

    try {
      // 1. Upload file to storage
      const fileExt = file.name.split('.').pop();
      const filePath = `${partId}/counter_receipt.${fileExt}`;

      console.log('Uploading file to storage:', filePath);
      const { error: uploadError } = await supabase.storage
        .from('part_files')
        .upload(filePath, file, {
          upsert: true,
          cacheControl: '3600'
        });

      if (uploadError) {
        console.error('File upload error:', uploadError);
        throw uploadError;
      }

      // 2. Create file record
      console.log('Creating file record');
      const { error: fileError } = await supabase
        .from('part_files')
        .upsert({
          part_id: partId,
          file_type: 'counter_receipt',
          file_path: filePath
        });

      if (fileError) {
        console.error('File record error:', fileError);
        throw fileError;
      }

      // 3. Update part status to completed (6)
      console.log('Updating part status to completed');
      const { error: partError } = await supabase
        .from('parts')
        .update({ status: 6 })
        .eq('id', partId);

      if (partError) {
        console.error('Part status update error:', partError);
        throw partError;
      }

      toast.success('Contrarecibo subido exitosamente');
      fetchParts();
    } catch (error: any) {
      console.error('Full error:', error);
      toast.error(`Error: ${error.message}`);
    } finally {
      setUploadingReceipt(null);
    }
  };

  const getStatusBadgeColor = (status: number) => {
    switch (status) {
      case 4: return 'bg-blue-100 text-blue-800';
      case 5: return 'bg-purple-100 text-purple-800';
      case 6: return 'bg-green-100 text-green-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusText = (status: number) => {
    switch (status) {
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
      <h1 className="text-2xl font-bold text-gray-900">Gestión de Contrarecibos</h1>

      <div className="bg-white shadow overflow-hidden sm:rounded-lg">
        <ul className="divide-y divide-gray-200">
          {parts.map((part) => (
            <li key={part.id} className="px-6 py-4">
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
                    <span>Proveedor: {part.provider?.name}</span>
                    <span>Precio: ${part.price}</span>
                    <span>Tipo: {part.is_cash ? 'Efectivo' : 'Transferencia'}</span>
                  </div>
                </div>
                <div className="flex items-center space-x-4">
                  {part.status === 5 && (
                    <div className="relative">
                      <input
                        type="file"
                        accept=".pdf,.jpg,.jpeg,.png"
                        onChange={(e) => {
                          const file = e.target.files?.[0];
                          if (file) handleUploadReceipt(part.id, file);
                        }}
                        className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                        disabled={uploadingReceipt === part.id}
                      />
                      <button
                        className={`text-blue-600 hover:text-blue-700 ${
                          uploadingReceipt === part.id ? 'opacity-50 cursor-not-allowed' : ''
                        }`}
                        title="Subir contrarecibo"
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
          ))}
          {parts.length === 0 && (
            <li className="px-6 py-12 text-center text-gray-500">
              No hay refacciones pendientes
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