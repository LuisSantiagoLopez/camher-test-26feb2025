import React, { useState, useEffect } from 'react';
import { X, AlertCircle } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { Unit, Provider } from '../../types';
import toast from 'react-hot-toast';
import PartForm from '../forms/PartForm';

interface CreatePartModalProps {
  units: Unit[];
  onClose: () => void;
  onSuccess: () => void;
}

export default function CreatePartModal({ units, onClose, onSuccess }: CreatePartModalProps) {
  const [loading, setLoading] = useState(false);
  const [providers, setProviders] = useState<Provider[]>([]);
  const [fetchStatus, setFetchStatus] = useState({
    loading: true,
    error: null,
    count: 0
  });

  const [formData, setFormData] = useState({
    unit_id: '',
    provider_id: '',
    description: [''],
    price: 0,
    unitary_price: [0],
    quantity: [1],
    is_cash: false,
    is_important: false,
    disposal_location: '',
    failure_report: {
      problemLocation: '',
      operator: '',
      description: '',
    },
    work_order: {
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

      console.log(`Found ${count} providers`);
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

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      // Create part record with initial status
      const { data: part, error: partError } = await supabase
        .from('parts')
        .insert({
          ...formData,
          status: 1, // Set to 1 (Created) initially
        })
        .select()
        .single();

      if (partError) throw partError;

      // Upload accident image if provided
      if (accidentImage && part) {
        const fileExt = accidentImage.name.split('.').pop();
        const filePath = `${part.id}/accident_proof.${fileExt}`;

        const { error: uploadError } = await supabase.storage
          .from('part_files')
          .upload(filePath, accidentImage);

        if (uploadError) throw uploadError;

        // Create file record
        const { error: fileError } = await supabase
          .from('part_files')
          .insert({
            part_id: part.id,
            file_type: 'accident_proof',
            file_path: filePath,
          });

        if (fileError) throw fileError;
      }

      toast.success('Refacción creada exitosamente');
      onSuccess();
    } catch (error: any) {
      toast.error(error.message || 'Error al crear la refacción');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-lg max-w-3xl w-full max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center p-6 border-b">
          <h2 className="text-xl font-semibold text-gray-900">Nueva Refacción</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-500">
            <X className="h-6 w-6" />
          </button>
        </div>

        {/* Provider Status Information */}
        {!fetchStatus.loading && (
          <div className="px-6 pt-4">
            <div className="bg-blue-50 border-l-4 border-blue-400 p-4">
              <div className="flex">
                <div className="flex-shrink-0">
                  <AlertCircle className="h-5 w-5 text-blue-400" />
                </div>
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