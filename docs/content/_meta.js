export default {
  index: <Entry title="Home" icon="home" />,
};

function Entry({ icon, title }) {
  return (
    <div style={{ display: "flex", alignItems: "center" }}>
      <span className="material-symbols-rounded">{icon}</span>
      <span style={{ marginLeft: 8 }}>{title}</span>
    </div>
  );
}
