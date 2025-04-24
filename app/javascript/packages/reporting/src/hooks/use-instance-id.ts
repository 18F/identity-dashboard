import { useMemo } from "preact/hooks";

let counter = 0;

/**
 * Returns a unique ID, can be used for form field label associations
 */
function useInstanceId(): string {
  return useMemo(() => {
    counter += 1;
    return String(counter);
  }, []);
}

export default useInstanceId;
