import React from 'react';

interface FailureReportProps {
  report: {
    problemLocation: string;
    operator: string;
    description: string;
  };
  setFormData: (data: any) => void;
}

const FailureReport: React.FC<FailureReportProps> = ({ report, setFormData }) => {
  const updateReport = (field: string, value: string) => {
    setFormData((prev: any) => ({
      ...prev,
      failure_report: {
        ...prev.failure_report,
        [field]: value,
      },
    }));
  };

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-medium text-gray-900">Reporte de falla</h3>
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700">
            Ubicación del problema
          </label>
          <input
            type="text"
            required
            value={report.problemLocation}
            onChange={(e) => updateReport('problemLocation', e.target.value)}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700">Operador</label>
          <input
            type="text"
            required
            value={report.operator}
            onChange={(e) => updateReport('operator', e.target.value)}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
          />
        </div>
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-700">
          Descripción de la falla
        </label>
        <textarea
          required
          value={report.description}
          onChange={(e) => updateReport('description', e.target.value)}
          rows={3}
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
        />
      </div>
    </div>
  );
};

export default FailureReport;