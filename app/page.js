'use client';

import { useState } from 'react';
import { QRCodeSVG } from 'qrcode.react';
import CryptoJS from 'crypto-js';

export default function Home() {
  const [roomID, setRoomID] = useState('');
  const [courseID, setCourseID] = useState('');
  const [timeSlot, setTimeSlot] = useState('');
  const [qrData, setQrData] = useState(null);

  const timeSlots = [
    '9:00 A.M.', '10:00 A.M.', '11:00 A.M.', '12:00 P.M.',
    '1:00 P.M.', '2:00 P.M.', '3:00 P.M.', '4:00 P.M.'
  ];

  const PRIVATE_KEY = 'your-secret-key'; // Replace with a secure key in production

  const generateQR = () => {
    if (roomID && courseID && timeSlot) {
      const payload = {
        RoomID: roomID,
        CourseID: courseID,
        TimeSlot: timeSlot
      };
      const jsonString = JSON.stringify(payload);
      const encrypted = CryptoJS.AES.encrypt(jsonString, PRIVATE_KEY).toString();
      setQrData(encrypted);
    }
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen p-4 bg-gray-100">
      <h1 className="text-3xl font-bold mb-6">QR Code Generator</h1>
      <input
        type="text"
        placeholder="Room ID"
        value={roomID}
        onChange={(e) => setRoomID(e.target.value)}
        className="mb-4 p-3 border border-gray-300 rounded-lg w-80 focus:outline-none focus:ring-2 focus:ring-blue-500"
      />
      <input
        type="text"
        placeholder="Course ID"
        value={courseID}
        onChange={(e) => setCourseID(e.target.value)}
        className="mb-4 p-3 border border-gray-300 rounded-lg w-80 focus:outline-none focus:ring-2 focus:ring-blue-500"
      />
      <select
        value={timeSlot}
        onChange={(e) => setTimeSlot(e.target.value)}
        className="mb-6 p-3 border border-gray-300 rounded-lg w-80 focus:outline-none focus:ring-2 focus:ring-blue-500"
      >
        <option value="">Select Time Slot</option>
        {timeSlots.map((slot) => (
          <option key={slot} value={slot}>{slot}</option>
        ))}
      </select>
      <button
        onClick={generateQR}
        className="mb-6 px-6 py-3 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
      >
        Show QR
      </button>
      {qrData && (
        <div className="p-4 bg-white rounded-lg shadow-md">
          <QRCodeSVG value={qrData} size={256} />\n        </div>
      )}
    </div>
  );
}
