import { useState, useEffect } from "preact/hooks";
import type { RefObject } from "preact";

function useElementWidth(ref: RefObject<HTMLElement>) {
  const [width, setWidth] = useState(undefined as number | undefined);

  useEffect(() => {
    const setCurrentWidth = () => setWidth(ref.current?.offsetWidth);
    const onResize = () => window.requestAnimationFrame(setCurrentWidth);

    setCurrentWidth();
    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, []);

  return width;
}

export default useElementWidth;
