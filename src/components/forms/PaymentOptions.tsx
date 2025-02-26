import React from 'react';

interface PaymentOptionsProps {
  isCash: boolean;
  isImportant: boolean;
  disposalLocation: string;
  setFormData: (data: any) => void;
}

const PaymentOptions: React.FC<PaymentOptionsProps> = ({
  isCash,
  isImportant,
  disposalLocation,
  setFormData,
}) => {
  return (
    <>
      <div className="grid grid-cols-2 gap-6">
        <div>
          <label className="block text-sm font-medium text-gray-700">Tipo de pago</label>
          <div className="mt-2">
            <label className="inline-flex items-center">
              <input
                type="checkbox"
                checked={isCash}
                onChange={(e) => setFormData((prev: any) => ({ ...prev, is_cash: e.target.checked }))}
                className="rounded border-gray-300 text-blue-600 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
              <span className="ml-2 text-sm text-gray-600">Pago en efectivo</span>
            </label>
          </div>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700">Prioridad</label>
          <div className="mt-2">
            <label className="inline-flex items-center">
              <input
                type="checkbox"
                checked={isImportant}
                onChange={(e) => setFormData((prev: any) => ({ ...prev, is_important: e.target.checked }))}
                className="rounded border-gray-300 text-blue-600 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
              <span className="ml-2 text-sm text-gray-600">Refacción importante</span>
            </label>
          </div>
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700">
          Ubicación de la parte desechada
        </label>
        <input
          type="text"
          required
          value={disposalLocation}
          onChange={(e) => setFormData((prev: any) => ({ ...prev, disposal_location: e.target.value }))}
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
        />
      </div>
    </>
  );
};

export default PaymentOptions;