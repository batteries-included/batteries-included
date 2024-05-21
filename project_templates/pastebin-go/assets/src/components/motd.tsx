interface MOTDDisplayProps {
  message: string;
}

export const MOTDDisplay = ({ message }: MOTDDisplayProps) => {
  return (
    message &&
    message != '' && (
      <div
        className="mx-2 mt-8 border border-blue-500 bg-blue-100 px-4 py-3 text-blue-700"
        role="alert">
        <p className="font-bold">Message Of the Day</p>
        <p className="text-sm">{message}</p>
      </div>
    )
  );
};
