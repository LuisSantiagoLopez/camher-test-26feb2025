import React from 'react';
import { CheckCircle2, XCircle, Clock } from 'lucide-react';

interface PartProgressBarProps {
  status: number;
  history?: {
    old_status: number;
    new_status: number;
    changed_at: string;
  }[];
}

export default function PartProgressBar({ status, history = [] }: PartProgressBarProps) {
  const stages = [
    { label: 'Creada', status: 1 },
    { label: 'Revisión Admin', status: 2 },
    { label: 'Revisión Proveedor', status: 3 },
    { label: 'Facturación', status: 4 },
    { label: 'Contrarecibo', status: 5 },
    { label: 'Completada', status: 6 },
  ];

  const getStageStatus = (stageStatus: number) => {
    if (status === -1) return 'cancelled';
    if (status >= stageStatus) return 'completed';
    if (status === stageStatus - 1) return 'current';
    return 'pending';
  };

  const getStageIcon = (stageStatus: string) => {
    switch (stageStatus) {
      case 'completed':
        return <CheckCircle2 className="h-6 w-6 text-green-500" />;
      case 'current':
        return <Clock className="h-6 w-6 text-blue-500 animate-pulse" />;
      case 'cancelled':
        return <XCircle className="h-6 w-6 text-red-500" />;
      default:
        return <div className="h-6 w-6 rounded-full border-2 border-gray-300" />;
    }
  };

  const getStageDate = (stageStatus: number) => {
    const stageChange = history?.find(h => h.new_status === stageStatus);
    return stageChange ? new Date(stageChange.changed_at).toLocaleDateString('es-MX') : null;
  };

  const getStatusTooltip = (stageStatus: number) => {
    switch (stageStatus) {
      case 1:
        return 'La refacción ha sido creada y está pendiente de revisión';
      case 2:
        return 'En revisión por el administrador debido al monto';
      case 3:
        return 'En revisión por el proveedor para cotización';
      case 4:
        return 'Esperando factura del proveedor';
      case 5:
        return 'Esperando contrarecibo del contador';
      case 6:
        return 'Proceso completado';
      default:
        return '';
    }
  };

  return (
    <div className="w-full">
      <div className="relative">
        {/* Progress Bar */}
        <div className="absolute top-1/2 left-0 w-full h-1 bg-gray-200 -translate-y-1/2" />
        <div
          className={`absolute top-1/2 left-0 h-1 -translate-y-1/2 transition-all duration-500 ${
            status === -1 ? 'bg-red-500' : 'bg-green-500'
          }`}
          style={{
            width: `${status === -1 ? 100 : (Math.min(status, 6) / 6) * 100}%`,
          }}
        />

        {/* Stages */}
        <div className="relative flex justify-between">
          {stages.map((stage, index) => {
            const stageStatus = getStageStatus(stage.status);
            const date = getStageDate(stage.status);
            const tooltip = getStatusTooltip(stage.status);

            return (
              <div
                key={stage.status}
                className={`flex flex-col items-center ${
                  index === 0 ? 'text-left' : index === stages.length - 1 ? 'text-right' : 'text-center'
                }`}
                title={tooltip}
              >
                <div className="bg-white p-1 rounded-full">
                  {getStageIcon(stageStatus)}
                </div>
                <div className="mt-2 space-y-1">
                  <p className={`text-sm font-medium ${
                    stageStatus === 'completed' ? 'text-green-600' :
                    stageStatus === 'current' ? 'text-blue-600' :
                    stageStatus === 'cancelled' ? 'text-red-600' :
                    'text-gray-500'
                  }`}>
                    {stage.label}
                  </p>
                  {date && (
                    <p className="text-xs text-gray-500">{date}</p>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}