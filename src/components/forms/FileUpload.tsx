import React from 'react';

interface FileUploadProps {
  setAccidentImage: (file: File | null) => void;
}

const FileUpload: React.FC<FileUploadProps> = ({ setAccidentImage }) => {
  return (
    <div>
      <label className="block text-sm font-medium text-gray-700">
        Fotografía del accidente
      </label>
      <input
        type="file"
        accept="image/*"
        required
        onChange={(e) => setAccidentImage(e.target.files?.[0] || null)}
        className="mt-1 block w-full text-sm text-gray-500
          file:mr-4 file:py-2 file:px-4
          file:rounded-md file:border-0
          file:text-sm file:font-semibold
          file:bg-blue-50 file:text-blue-700
          hover:file:bg-blue-100"
      />
    </div>
  );
};

export default FileUpload;