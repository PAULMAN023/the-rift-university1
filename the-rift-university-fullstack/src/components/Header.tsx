import Link from "next/link";
import { site } from "@/lib/site";
const links = [["About","/about"],["Schools","/schools"],["Programmes","/programmes"],["Admissions","/admissions"],["Fees","/fees"],["News","/news"],["Contact","/contact"]];
export default function Header() {
 return <header className="header"><div className="navwrap"><Link href="/" className="brand"><span className="crest">TRU</span><span><b>{site.name}</b><small>{site.motto}</small></span></Link><nav aria-label="Main navigation">{links.map(([label,url])=><Link key={url} href={url}>{label}</Link>)}</nav><div className="navactions"><Link className="login" href="/login">Sign in</Link><Link className="button gold small" href="/apply">Apply Now</Link></div></div></header>
}
