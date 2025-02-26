import React, { useState, useEffect } from 'react';
import { X, Download } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { Part, PartFile } from '../../types';
import toast from 'react-hot-toast';

interface PartDetailsModalProps {
  part: Part;
  onClose: () => void;
}

export default function PartDetailsModal({ part, onClose }: PartDetailsModalProps) {
  const [files, setFiles] = useState<PartFile[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchFiles();
  }, [part.id]);

  const fetchFiles = async () => {
    try {
      const { data, error } = await supabase
        .from('part_files')
        .select('*')
        .eq('part_id', part.id)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setFiles(data || []);
    } catch (error: any) {
      toast.error('Error al cargar archivos');
    } finally {
      setLoading(false);
    }
  };

  const handleDownloadFile = async (file: PartFile) => {
    try {
      const { data, error } = await supabase.storage
        .from('part_files')
        .download(file.file_path);

      if (error) throw error;

      // Create blob URL and trigger download
      const url = window.URL.createObjectURL(data);
      const a = document.createElement('a');
      a.href = url;
      a.download = file.file_path.split('/').pop() || 'file';
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
    } catch (error: any) {
      toast.error('Error al descargar archivo');
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
      default: return 'Desconocido';
    }
  };

  const getFileTypeText = (type: string) => {
    switch (type) {
      case 'accident_proof': return 'Prueba de accidente';
      case 'invoice': return 'Factura';
      case 'counter_receipt': return 'Contrarecibo';
      default: return type;
    }
  };

  return (
    <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center p-6 border-b">
          <h2 className="text-xl font-semibold text-gray-900">Detalles de la Refacción</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-500">
            <X className="h-6 w-6" />
          </button>
        </div>

        <div className="p-6 space-y-6">
          {/* Status */}
          <div className="flex items-center space-x-3">
            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusBadgeColor(part.status)}`}>
              {getStatusText(part.status)}
            </span>
            <span className="text-sm text-gray-500">
              Creado el: {new Date(part.created_at).toLocaleDateString()}
            </span>
          </div>

          {/* Basic Info */}
          <div className="grid grid-cols-2 gap-6">
            <div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">Información General</h3>
              <dl className="space-y-2">
                <div>
                  <dt className="text-sm font-medium text-gray-500">Unidad</dt>
                  <dd className="text-sm text-gray-900">{part.unit?.name}</dd>
                </div>
                <div>
                  <dt className="text-sm font-medium text-gray-500">Ubicación de desecho</dt>
                  <dd className="text-sm text-gray-900">{part.disposal_location}</dd>
                </div>
                <div>
                  <dt className="text-sm font-medium text-gray-500">Tipo de pago</dt>
                  <dd className="text-sm text-gray-900">{part.is_cash ? 'Efectivo' : 'Transferencia'}</dd>
                </div>
                <div>
                  <dt className="text-sm font-medium text-gray-500">Prioridad</dt>
                  <dd className="text-sm text-gray-900">{part.is_important ? 'Importante' : 'Normal'}</dd>
                </div>
              </dl>
            </div>

            <div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">Refacciones</h3>
              <div className="space-y-2">
                {part.description?.map((desc, index) => (
                  <div key={index} className="flex items-center justify-between text-sm">
                    <span className="text-gray-900">{desc}</span>
                    <div className="text-gray-500">
                      <span className="mr-2">${part.unitary_price?.[index]}</span>
                      <span>x {part.quantity?.[index]}</span>
                    </div>
                  </div>
                ))}
                <div className="pt-2 border-t">
                  <div className="flex justify-between font-medium">
                    <span>Total</span>
                    <span>${part.price}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Failure Report */}
          <div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">Reporte de Falla</h3>
            <dl className="grid grid-cols-2 gap-4">
              <div>
                <dt className="text-sm font-medium text-gray-500">Ubicación del problema</dt>
                <dd className="text-sm text-gray-900">{part.failure_report?.problemLocation}</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Operador</dt>
                <dd className="text-sm text-gray-900">{part.failure_report?.operator}</dd>
              </div>
              <div className="col-span-2">
                <dt className="text-sm font-medium text-gray-500">Descripción</dt>
                <dd className="text-sm text-gray-900">{part.failure_report?.description}</dd>
              </div>
            </dl>
          </div>

          {/* Work Order */}
          <div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">Orden de Trabajo</h3>
            <dl className="grid grid-cols-2 gap-4">
              <div>
                <dt className="text-sm font-medium text-gray-500">Trabajo a realizar</dt>
                <dd className="text-sm text-gray-900">{part.work_order?.jobToBeDone}</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Persona a cargo</dt>
                <dd className="text-sm text-gray-900">{part.work_order?.personInCharge}</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Refacción necesaria</dt>
                <dd className="text-sm text-gray-900">{part.work_order?.sparePart}</dd>
              </div>
              <div>
                <dt className="text-sm font-medium text-gray-500">Observaciones</dt>
                <dd className="text-sm text-gray-900">{part.work_order?.observation}</dd>
              </div>
            </dl>
          </div>

          {/* Files */}
          <div>
            <h3 className="text-lg font-medium text-gray-900 mb-2">Archivos</h3>
            {loading ? (
              <div className="flex justify-center py-4">
                <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-500" />
              </div>
            ) : (
              <ul className="divide-y divide-gray-200">
                {files.map((file) => (
                  <li key={file.id} className="py-3 flex justify-between items-center">
                    <div>
                      <p className="text-sm font-medium text-gray-900">
                        {getFileTypeText(file.file_type)}
                      </p>
                      <p className="text-sm text-gray-500">
                        {new Date(file.created_at).toLocaleDateString()}
                      </p>
                    </div>
                    <button
                      onClick={() => handleDownloadFile(file)}
                      className="text-blue-600 hover:text-blue-700"
                    >
                      <Download className="h-5 w-5" />
                    </button>
                  </li>
                ))}
                {files.length === 0 && (
                  <li className="py-4 text-center text-sm text-gray-500">
                    No hay archivos disponibles
                  </li>
                )}
              </ul>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}