import React from 'react';
import { Unit, Provider } from '../../types';
import { AlertCircle } from 'lucide-react';

interface UnitProviderSelectProps {
  units: Unit[];
  providers: Provider[];
  formData: any;
  setFormData: (data: any) => void;
}

export default function UnitProviderSelect({
  units,
  providers,
  formData,
  setFormData,
}: UnitProviderSelectProps) {
  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-6">
        <div>
          <label className="block text-sm font-medium text-gray-700">Unidad</label>
          <select
            required
            value={formData.unit_id}
            onChange={(e) => setFormData({ ...formData, unit_id: e.target.value })}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          >
            <option value="">Seleccionar unidad</option>
            {units.map((unit) => (
              <option key={unit.id} value={unit.id}>
                {unit.name}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700">Proveedor</label>
          <select
            required
            value={formData.provider_id}
            onChange={(e) => setFormData({ ...formData, provider_id: e.target.value })}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          >
            <option value="">Seleccionar proveedor</option>
            {providers.map((provider) => (
              <option key={provider.id} value={provider.id}>
                {provider.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Provider Status Information */}
      {providers.length === 0 && (
        <div className="bg-yellow-50 border-l-4 border-yellow-400 p-4">
          <div className="flex">
            <div className="flex-shrink-0">
              <AlertCircle className="h-5 w-5 text-yellow-400" />
            </div>
            <div className="ml-3">
              <p className="text-sm text-yellow-700">
                No hay proveedores disponibles. Esto puede deberse a:
              </p>
              <ul className="mt-2 list-disc list-inside text-sm text-yellow-700">
                <li>No hay proveedores registrados en el sistema</li>
                <li>Los proveedores existentes no han sido verificados por el administrador</li>
                <li>Los proveedores no han completado su registro</li>
              </ul>
              <p className="mt-2 text-sm text-yellow-700">
                Contacta al administrador para verificar el estado de los proveedores.
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}