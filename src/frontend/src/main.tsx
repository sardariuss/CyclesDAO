import ReactDOM from "react-dom/client";
import "./index.css";
import App from "./App";

// to fix decoder of agent-js
window.global = window;

// to fix plug
declare global {
	interface Window {
		ic: any;
	}
}
let ic = window.ic;

ReactDOM.createRoot(document.getElementById("root")!).render(<App />);
