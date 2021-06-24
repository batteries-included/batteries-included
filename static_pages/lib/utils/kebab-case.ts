const kebabCase = (str?: string): string => {
  return (
    (str || '').match(
      /[A-Z]{2,}(?=[A-Z][a-z]+[0-9]*|\b)|[A-Z]?[a-z]+[0-9]*|[A-Z]|[0-9]+/g
    ) || []
  )
    .map((x: string) => x.toLowerCase())
    .join('-');
};

export default kebabCase;
