import nextra from "nextra";

const withNextra = nextra({
  // ... Other Nextra config options
  defaultShowCopyCode: true,
});

// You can include other Next.js configuration options here, in addition to Nextra settings:
export default withNextra({
  output: "export",
  images: {
    unoptimized: true, // mandatory, otherwise won't export
  },
});
