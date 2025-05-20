import { createContext, VNode, ComponentChildren } from "preact";
import { StateUpdater, useContext, useEffect, useState } from "preact/hooks";

interface AgenciesContextValues {
  agencies: string[];
  setAgencies: (value: string[] | ((prevState: string[]) => string[])) => void; // Adjusted type
}

const AgenciesContext = createContext<AgenciesContextValues>({
  agencies: [],
  setAgencies: () => {
    // Default implementation that matches the type
    throw new Error("setAgencies function must be overridden by a provider");
  },
});

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