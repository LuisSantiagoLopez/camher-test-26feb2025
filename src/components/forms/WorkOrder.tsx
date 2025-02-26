import React from 'react';

interface WorkOrderProps {
  order: {
    jobToBeDone: string;
    personInCharge: string;
    sparePart: string;
    observation: string;
  };
  setFormData: (data: any) => void;
}

const WorkOrder: React.FC<WorkOrderProps> = ({ order, setFormData }) => {
  const updateOrder = (field: string, value: string) => {
    setFormData((prev: any) => ({
      ...prev,
      work_order: {
        ...prev.work_order,
        [field]: value,
      },
    }));
  };

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-medium text-gray-900">Orden de trabajo</h3>
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700">
            Trabajo a realizar
          </label>
          <input
            type="text"
            required
            value={order.jobToBeDone}
            onChange={(e) => updateOrder('jobToBeDone', e.target.value)}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700">
            Persona a cargo
          </label>
          <input
            type="text"
            required
            value={order.personInCharge}
            onChange={(e) => updateOrder('personInCharge', e.target.value)}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          />
        </div>
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700">
          Refacción necesaria
        </label>
        <input
          type="text"
          required
          value={order.sparePart}
          onChange={(e) => updateOrder('sparePart', e.target.value)}
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700">
          Observaciones
        </label>
        <textarea
          value={order.observation}
          onChange={(e) => updateOrder('observation', e.target.value)}
          rows={3}
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
        />
      </div>
    </div>
  );
};

export default WorkOrder;