import { generateStaticParamsFor, importPage } from "nextra/pages";
import { useMDXComponents } from "../../mdx-components";

export async function generateMetadata(props) {
  const { mdxPath } = await props.params;
  const { metadata } = await importPage(mdxPath);
  return {
    metadataBase: new URL("https://fitnesschallenges.pages.dev/"),
    title: metadata.title || "Fitness Challenges",
    description:
      metadata.description ||
      "Compete in fitness-based challenges with friends and family.",
    icons: {
      icon: "/icon.png",
    },
    openGraph: {
      type: "website",
      url: "https://fitnesschallenges.pages.dev/",
      siteName: "Fitness Challenges",
      title: metadata.title || "Fitness Challenges",
      description:
        metadata.description ||
        "Compete in fitness-based challenges with friends and family.",
      determiner: "the",
      locale: "en_US",
      images: {
        url: "/icon.png",
        width: 4888,
        height: 1622,
        alt: "Fitness Challenge's icon (rocket)",
        type: "image/png",
      },
    },
  };
}

//export const runtime = "edge";
export const generateStaticParams = generateStaticParamsFor("mdxPath");

const Wrapper = useMDXComponents().wrapper;

export default async function Page(props) {
  const params = await props.params;
  const result = await importPage(params.mdxPath);
  const { default: MDXContent, toc, metadata } = result;
  return (
    <Wrapper toc={toc} metadata={metadata}>
      <MDXContent {...props} params={params} />
    </Wrapper>
  );
}
