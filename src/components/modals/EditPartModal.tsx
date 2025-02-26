import React, { useState, useEffect } from 'react';
import { X } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { Part, Unit, Provider } from '../../types';
import toast from 'react-hot-toast';
import PartForm from '../forms/PartForm';

interface EditPartModalProps {
  part: Part;
  units: Unit[];
  onClose: () => void;
  onSuccess: () => void;
}

export default function EditPartModal({ part, units, onClose, onSuccess }: EditPartModalProps) {
  const [loading, setLoading] = useState(false);
  const [providers, setProviders] = useState<Provider[]>([]);
  const [fetchStatus, setFetchStatus] = useState({
    loading: true,
    error: null,
    count: 0
  });

  const [formData, setFormData] = useState({
    unit_id: part.unit_id,
    provider_id: part.provider_id || '',
    description: part.description || [''],
    price: part.price || 0,
    unitary_price: part.unitary_price || [0],
    quantity: part.quantity || [1],
    is_cash: part.is_cash || false,
    is_important: part.is_important || false,
    disposal_location: part.disposal_location || '',
    failure_report: part.failure_report || {
      problemLocation: '',
      operator: '',
      description: '',
    },
    work_order: part.work_order || {
      jobToBeDone: '',
      personInCharge: '',
      sparePart: '',
      observation: '',
    },
  });

  const [accidentImage, setAccidentImage] = useState<File | null>(null);

  useEffect(() => {
    fetchProviders();
  }, []);

  const fetchProviders = async () => {
    setFetchStatus(prev => ({ ...prev, loading: true, error: null }));
    
    try {
      const { data: providerData, error: providerError, count } = await supabase
        .from('providers')
        .select('*', { count: 'exact' })
        .order('name');

      if (providerError) throw providerError;

      setProviders(providerData || []);
      setFetchStatus({
        loading: false,
        error: null,
        count: count || 0
      });
    } catch (error: any) {
      console.error('Error fetching providers:', error);
      setFetchStatus({
        loading: false,
        error: error.message,
        count: 0
      });
      toast.error('Error al cargar proveedores: ' + error.message);
    }
  };

  const determineNewStatus = (data: typeof formData): number => {
    // Si no hay proveedor seleccionado, mantener en estado inicial
    if (!data.provider_id) {
      return 1;
    }

    // Si el proveedor cambió, mandar a revisión de admin
    if (part.provider_id !== data.provider_id) {
      return 2;
    }

    // Si el precio o tipo de pago cambió, determinar si necesita revisión
    if (part.price !== data.price || part.is_cash !== data.is_cash) {
      if ((data.is_cash && data.price > 500) || (!data.is_cash && data.price > 10000)) {
        return 2; // Necesita revisión de admin
      }
      return 3; // Va directo al proveedor
    }

    // Si hay cambios pero no significativos y ya tiene proveedor, mandar al proveedor
    if (data.provider_id) {
      return 3;
    }

    // Si no hay cambios significativos, mantener el estado actual
    return part.status;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      // Determinar el nuevo estado
      const newStatus = determineNewStatus(formData);

      // Update part record with new status
      const { error: partError } = await supabase
        .from('parts')
        .update({
          ...formData,
          status: newStatus
        })
        .eq('id', part.id);

      if (partError) throw partError;

      // Solo manejar la imagen si se proporcionó una nueva
      if (accidentImage) {
        const fileExt = accidentImage.name.split('.').pop();
        const filePath = `${part.id}/accident_proof.${fileExt}`;

        const { error: uploadError } = await supabase.storage
          .from('part_files')
          .upload(filePath, accidentImage, { upsert: true });

        if (uploadError) throw uploadError;

        // Update or create file record
        const { error: fileError } = await supabase
          .from('part_files')
          .upsert({
            part_id: part.id,
            file_type: 'accident_proof',
            file_path: filePath,
          });

        if (fileError) throw fileError;
      }

      // Mensaje específico según el nuevo estado
      let successMessage = 'Refacción actualizada exitosamente';
      if (newStatus === 2) {
        successMessage += ' y enviada para revisión del administrador';
      } else if (newStatus === 3) {
        successMessage += ' y enviada al proveedor';
      }

      toast.success(successMessage);
      onSuccess();
    } catch (error: any) {
      toast.error(error.message || 'Error al actualizar la refacción');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg max-w-3xl w-full max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center p-6 border-b">
          <h2 className="text-xl font-semibold text-gray-900">Editar Refacción</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-500">
            <X className="h-6 w-6" />
          </button>
        </div>

        {/* Provider Status Information */}
        {!fetchStatus.loading && (
          <div className="px-6 pt-4">
            <div className="bg-blue-50 border-l-4 border-blue-400 p-4">
              <div className="flex">
                <div className="ml-3">
                  <h3 className="text-sm font-medium text-blue-800">Estado de Proveedores</h3>
                  <div className="mt-2 text-sm text-blue-700">
                    <p>Proveedores disponibles: {fetchStatus.count}</p>
                  </div>
                  {fetchStatus.error && (
                    <p className="mt-2 text-sm text-red-600">
                      Error: {fetchStatus.error}
                    </p>
                  )}
                </div>
              </div>
            </div>
          </div>
        )}

        <PartForm
          units={units}
          providers={providers}
          formData={formData}
          setFormData={setFormData}
          loading={loading}
          onSubmit={handleSubmit}
          onClose={onClose}
          setAccidentImage={setAccidentImage}
        />
      </div>
    </div>
  );
}