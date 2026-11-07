# thienhuunguyen.github.io

Source of Thien Huu Nguyen's website, served by GitHub Pages at https://thienhuunguyen.github.io/

## Editing

1. Edit any `.html` file (or add a new page, e.g. `talks.html`, and link it from the nav menu
   in each page: search for `<nav id="navbar"`).
2. Put PDFs in `pubs/` and images in `assets/thien-img/`, then link them with relative paths
   (`pubs/paper.pdf`, `assets/thien-img/photo.png`).
3. Preview locally by opening `index.html` in a browser.
4. Publish: `./push.sh "short description of the change"`

`push.sh` checks for broken local links and oversized files, regenerates
`tools/publications.md` (markdown list for the group website), commits, and pushes.

## Notes

- Icons: Font Awesome 5 Free from cdnjs (only free icons: `fas`, `far`, `fab`).
- No server-side code (PHP) runs on GitHub Pages.
- The repo is public; don't put private files here.
