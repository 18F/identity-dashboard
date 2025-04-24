import { createContext, VNode, ComponentChildren } from "preact";
import { StateUpdater, useContext, useEffect, useState } from "preact/hooks";

interface AgenciesContextValues {
  agencies: string[];
  setAgencies: StateUpdater<string[]>;
}

const AgenciesContext = createContext({
  agencies: [],
  setAgencies: () => null,
} as AgenciesContextValues);

function AgenciesContextProvider({ children }: { children: ComponentChildren }): VNode {
  const [agencies, setAgencies] = useState([] as string[]);
  return (
    <AgenciesContext.Provider value={{ agencies, setAgencies }}>
      {children}
    </AgenciesContext.Provider>
  );
}

function useAgencies(data: { agency: string }[] | undefined): void {
  const { setAgencies } = useContext(AgenciesContext);
  useEffect(() => {
    if (!data) {
      return;
    }

    const allAgencies = Array.from(new Set(data.map((d) => d.agency)))
      .filter((x) => !!x)
      .sort();

    setAgencies(allAgencies);
  }, [data]);
}

export { AgenciesContextProvider, AgenciesContext, useAgencies };
