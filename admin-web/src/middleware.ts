import { NextRequest, NextResponse } from "next/server";
import { stackServerApp } from "@/stack";

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Allow static files, api routes, and Stack Auth handlers through
  if (
    pathname.startsWith("/_next") ||
    pathname.startsWith("/api") ||
    pathname.startsWith("/handler") ||
    pathname.startsWith("/favicon.ico")
  ) {
    return NextResponse.next();
  }

  try {
    const user = await stackServerApp.getUser();

    // If accessing login while already authenticated, redirect to root dashboard
    if (pathname === "/login") {
      if (user) {
        return NextResponse.redirect(new URL("/", request.url));
      }
      return NextResponse.next();
    }

    // Protect all admin control plane routes
    if (!user) {
      const signInUrl = new URL("/handler/sign-in", request.url);
      return NextResponse.redirect(signInUrl);
    }
  } catch (err) {
    return NextResponse.next();
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico).*)"],
};

