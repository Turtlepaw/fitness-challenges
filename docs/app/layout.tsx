import { Footer, Layout, Navbar } from "nextra-theme-docs";
import { Banner, Head } from "nextra/components";
import { getPageMap } from "nextra/page-map";
import "nextra-theme-docs/style.css";
import "material-symbols";
import "../styles.css";
import type { Metadata } from "next";
import type { PropsWithChildren } from "react";
import { importPage } from "nextra/pages";

const banner = (
  <Banner storageKey="">
    <></>
  </Banner>
);

const logo = (
  <>
    <span className="material-symbols-rounded">rocket_launch</span>
  </>
);

const navbar = (
  <Navbar
    logo={
      <div style={{ display: "flex", alignItems: "center" }}>
        {logo}
        <b style={{ marginLeft: 5 }}>Fitness Challenges</b>
      </div>
    }
    // ... Your additional navbar options
  />
);

const footer = <Footer></Footer>;

export default async function RootLayout({ children }: PropsWithChildren) {
  return (
    <html
      // Not required, but good for SEO
      lang="en"
      // Required to be set
      dir="ltr"
      // Suggested by `next-themes` package https://github.com/pacocoursey/next-themes#with-app
      suppressHydrationWarning
    >
      <Head
      // ... Your additional head options
      >
        {/* Your additional tags should be passed as `children` of `<Head>` element */}
      </Head>
      <body>
        <Layout
          //banner={banner} // uncomment to show optional banner
          navbar={navbar}
          pageMap={await getPageMap()}
          docsRepositoryBase="https://github.com/Turtlepaw/fitness-challenges"
          footer={footer}
          darkMode
        >
          {children}
        </Layout>
      </body>
    </html>
  );
}
