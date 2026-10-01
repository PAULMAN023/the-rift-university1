import type {Metadata} from "next"; import "./globals.css"; import Shell from "@/components/Shell"; import {site} from "@/lib/site";
export const metadata:Metadata={title:{default:site.name,template:`%s | ${site.short}`},description:site.slogan};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="en"><body><Shell>{children}</Shell></body></html>}
