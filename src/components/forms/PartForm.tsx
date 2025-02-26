import React from 'react';
import { Unit, Provider } from '../../types';
import UnitProviderSelect from './UnitProviderSelect';
import PartDescriptionList from './PartDescriptionList';
import PaymentOptions from './PaymentOptions';
import FailureReport from './FailureReport';
import WorkOrder from './WorkOrder';
import FileUpload from './FileUpload';

interface PartFormProps {
  units: Unit[];
  providers: Provider[];
  formData: any;
  setFormData: (data: any) => void;
  loading: boolean;
  onSubmit: (e: React.FormEvent) => void;
  onClose: () => void;
  setAccidentImage: (file: File | null) => void;
}

export default function PartForm({
  units,
  providers,
  formData,
  setFormData,
  loading,
  onSubmit,
  onClose,
  setAccidentImage,
}: PartFormProps) {
  return (
    <form onSubmit={onSubmit} className="p-6 space-y-8">
      {/* Each section is now wrapped in a card-like container */}
      <div className="bg-white rounded-lg border border-gray-200 shadow-sm overflow-hidden">
        <div className="p-6 space-y-6">
          <h3 className="text-lg font-semibold text-gray-900 border-b pb-4">
            Información Básica
          </h3>
          <UnitProviderSelect
            units={units}
            providers={providers}
            formData={formData}
            setFormData={setFormData}
          />
        </div>
      </div>

      <div className="bg-white rounded-lg border border-gray-200 shadow-sm overflow-hidden">
        <div className="p-6 space-y-6">
          <h3 className="text-lg font-semibold text-gray-900 border-b pb-4">
            Detalles de Refacciones
          </h3>
          <PartDescriptionList
            descriptions={formData.description}
            unitaryPrices={formData.unitary_price}
            quantities={formData.quantity}
            setFormData={setFormData}
          />
        </div>
      </div>

      <div className="bg-white rounded-lg border border-gray-200 shadow-sm overflow-hidden">
        <div className="p-6 space-y-6">
          <h3 className="text-lg font-semibold text-gray-900 border-b pb-4">
            Opciones de Pago y Ubicación
          </h3>
          <PaymentOptions
            isCash={formData.is_cash}
            isImportant={formData.is_important}
            disposalLocation={formData.disposal_location}
            setFormData={setFormData}
          />
        </div>
      </div>

      <div className="bg-white rounded-lg border border-gray-200 shadow-sm overflow-hidden">
        <div className="p-6 space-y-6">
          <h3 className="text-lg font-semibold text-gray-900 border-b pb-4">
            Reporte de Falla
          </h3>
          <FailureReport
            report={formData.failure_report}
            setFormData={setFormData}
          />
        </div>
      </div>

      <div className="bg-white rounded-lg border border-gray-200 shadow-sm overflow-hidden">
        <div className="p-6 space-y-6">
          <h3 className="text-lg font-semibold text-gray-900 border-b pb-4">
            Orden de Trabajo
          </h3>
          <WorkOrder
            order={formData.work_order}
            setFormData={setFormData}
          />
        </div>
      </div>

      <div className="bg-white rounded-lg border border-gray-200 shadow-sm overflow-hidden">
        <div className="p-6 space-y-6">
          <h3 className="text-lg font-semibold text-gray-900 border-b pb-4">
            Documentación
          </h3>
          <FileUpload
            setAccidentImage={setAccidentImage}
          />
        </div>
      </div>

      <div className="flex justify-end space-x-3 pt-6">
        <button
          type="button"
          onClick={onClose}
          className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
        >
          Cancelar
        </button>
        <button
          type="submit"
          disabled={loading}
          className="inline-flex justify-center px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-md shadow-sm hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {loading ? 'Guardando...' : 'Guardar'}
        </button>
      </div>
    </form>
  );
}