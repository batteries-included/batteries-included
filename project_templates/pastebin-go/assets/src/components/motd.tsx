interface MOTDDisplayProps {
  message: string;
}

export const MOTDDisplay = ({ message }: MOTDDisplayProps) => {
  return (
    message &&
    message != '' && (
      <div
        className="mt-8 mx-2 bg-blue-100 border border-blue-500 text-blue-700 px-4 py-3"
        role="alert">
        <p className="font-bold">Message Of the Day</p>
        <p className="text-sm">{message}</p>
      </div>
    )
  );
};
