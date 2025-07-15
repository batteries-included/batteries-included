export default function HiddenInput({
  id,
  name,
  value,
}: {
  id: string;
  name: string;
  value?: string;
}) {
  return <input type="hidden" id={id} name={name} value={value} />;
}
