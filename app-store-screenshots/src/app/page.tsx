"use client";

import { type CSSProperties, useEffect, useRef, useState } from "react";
import { toPng } from "html-to-image";
import JSZip from "jszip";

const W = 1320;
const H = 2868;

const SIZES = [
  { label: '6.9"', w: 1320, h: 2868 },
  { label: '6.5"', w: 1284, h: 2778 },
  { label: '6.3"', w: 1206, h: 2622 },
  { label: '6.1"', w: 1125, h: 2436 },
] as const;

const EXPORT_MIME_TYPE = "image/png";
const EXPORT_EXTENSION = "png";

const MK_W = 1022;
const MK_H = 2082;
const SC_L = (52 / MK_W) * 100;
const SC_T = (46 / MK_H) * 100;
const SC_W = (918 / MK_W) * 100;
const SC_H = (1990 / MK_H) * 100;
const SC_RX = (126 / 918) * 100;
const SC_RY = (126 / 1990) * 100;

const slides = [
  {
    slug: "preserve",
    kicker: "A studio for family memories",
    title: ["Preserve the", "Magic"],
    body:
      "Create a beautiful home for every drawing, painting, and paper masterpiece before it fades into a pile.",
    accent: "#F2784B",
    accentSoft: "rgba(242, 120, 75, 0.22)",
    backgroundBase: "#2D1B16",
    backdrop:
      "radial-gradient(circle at 18% 20%, rgba(242,120,75,0.28), transparent 23%), radial-gradient(circle at 86% 82%, rgba(212,115,108,0.22), transparent 22%), linear-gradient(145deg, #2D1B16 0%, #4A271B 44%, #1B120E 100%)",
    screenshot: "/screenshots/01-preserve.png",
    pills: ["Archive artwork", "Keep every masterpiece"],
    layout: "hero" as const,
  },
  {
    slug: "capture",
    kicker: "Made for fast kitchen-table saves",
    title: ["Capture Every", "Creation"],
    body:
      "Snap artwork in seconds, add it to the right child, and keep the growing collection beautifully organized.",
    accent: "#A8C5A0",
    accentSoft: "rgba(168, 197, 160, 0.24)",
    backgroundBase: "#261A16",
    backdrop:
      "radial-gradient(circle at 50% 16%, rgba(168,197,160,0.20), transparent 24%), radial-gradient(circle at 12% 80%, rgba(126,184,218,0.16), transparent 18%), linear-gradient(180deg, #261A16 0%, #3A261F 42%, #1C120F 100%)",
    screenshot: "/screenshots/02-capture.png",
    pills: ["One quick scan", "Ready in seconds"],
    layout: "center" as const,
  },
  {
    slug: "captions",
    kicker: "Tiny stories, saved forever",
    title: ["AI-Powered", "Captions"],
    body:
      "Turn every artwork into a keepsake with thoughtful titles and captions that help each creation feel unforgettable.",
    accent: "#7EB8DA",
    accentSoft: "rgba(126, 184, 218, 0.24)",
    backgroundBase: "#17181E",
    backdrop:
      "radial-gradient(circle at 84% 18%, rgba(126,184,218,0.28), transparent 24%), radial-gradient(circle at 8% 86%, rgba(184,169,212,0.18), transparent 22%), linear-gradient(160deg, #17181E 0%, #1B2937 40%, #121116 100%)",
    screenshot: "/screenshots/03-captions.png",
    pills: ["Smart titles", "Sweet captions", "More context"],
    layout: "split-right" as const,
  },
  {
    slug: "voice",
    kicker: "Keep their words with the art",
    title: ["Add Voice", "Notes"],
    body:
      "Record the little explanation behind each piece so their imagination lives alongside the artwork itself.",
    accent: "#B8A9D4",
    accentSoft: "rgba(184, 169, 212, 0.24)",
    backgroundBase: "#221620",
    backdrop:
      "radial-gradient(circle at 22% 18%, rgba(184,169,212,0.26), transparent 20%), radial-gradient(circle at 88% 74%, rgba(242,120,75,0.14), transparent 18%), linear-gradient(150deg, #221620 0%, #33213A 48%, #171018 100%)",
    screenshot: "/screenshots/04-voice.png",
    pills: ["Capture their voice", "Hear the memory again"],
    layout: "split-left" as const,
  },
  {
    slug: "share",
    kicker: "Grandparents will love this one",
    title: ["Share &", "Celebrate"],
    body:
      "Send each masterpiece to family and keep everyone close to the moments, milestones, and creativity that matter.",
    accent: "#D4736C",
    accentSoft: "rgba(212, 115, 108, 0.24)",
    backgroundBase: "#2B1716",
    backdrop:
      "radial-gradient(circle at 16% 76%, rgba(212,115,108,0.22), transparent 22%), radial-gradient(circle at 86% 18%, rgba(242,120,75,0.18), transparent 18%), linear-gradient(155deg, #2B1716 0%, #4A2422 44%, #1A1110 100%)",
    screenshot: "/screenshots/05-share.png",
    pills: ["Family", "Grandparents", "Keepsakes"],
    layout: "celebrate" as const,
  },
] as const;

function wait(ms: number) {
  return new Promise((resolve) => window.setTimeout(resolve, ms));
}

async function loadImage(dataUrl: string) {
  const image = new Image();
  image.decoding = "async";
  image.src = dataUrl;

  await image.decode();
  return image;
}

async function canvasToBlob(canvas: HTMLCanvasElement, type: string) {
  return new Promise<Blob>((resolve, reject) => {
    canvas.toBlob((blob) => {
      if (!blob) {
        reject(new Error("Unable to create export blob."));
        return;
      }

      resolve(blob);
    }, type);
  });
}

async function renderOpaqueBlob(
  dataUrl: string,
  width: number,
  height: number,
  backgroundColor: string,
) {
  const image = await loadImage(dataUrl);

  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;

  const ctx = canvas.getContext("2d");
  if (!ctx) {
    throw new Error("Unable to create canvas context.");
  }

  // Fill the canvas first so the final PNG has no transparent pixels.
  ctx.fillStyle = backgroundColor;
  ctx.fillRect(0, 0, width, height);
  ctx.drawImage(image, 0, 0, width, height);
  return canvasToBlob(canvas, EXPORT_MIME_TYPE);
}

function downloadBlob(blob: Blob, filename: string) {
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  link.click();

  window.setTimeout(() => URL.revokeObjectURL(url), 1000);
}

function getArchiveName() {
  return `little-artist-app-store-screenshots-${new Date().toISOString().slice(0, 10)}`;
}

function getExportFilename(index: number, slug: string, width: number, height: number) {
  return `${String(index + 1).padStart(2, "0")}-${slug}-${width}x${height}.${EXPORT_EXTENSION}`;
}

function Phone({
  src,
  alt,
  className = "",
  style,
  imageStyle,
}: {
  src: string;
  alt: string;
  className?: string;
  style?: CSSProperties;
  imageStyle?: CSSProperties;
}) {
  return (
    <div
      className={`relative ${className}`}
      style={{ aspectRatio: `${MK_W}/${MK_H}`, ...style }}
    >
      <img
        src="/mockup.png"
        alt=""
        className="block h-full w-full"
        draggable={false}
      />
      <div
        className="absolute z-10 overflow-hidden"
        style={{
          left: `${SC_L}%`,
          top: `${SC_T}%`,
          width: `${SC_W}%`,
          height: `${SC_H}%`,
          borderRadius: `${SC_RX}% / ${SC_RY}%`,
        }}
      >
        <img
          src={src}
          alt={alt}
          className="block h-full w-full object-cover object-top"
          draggable={false}
          style={imageStyle}
        />
      </div>
    </div>
  );
}

function BrandLockup({ accent }: { accent: string }) {
  return (
    <div className="flex items-center gap-5">
      <div
        className="flex h-24 w-24 items-center justify-center rounded-[30px] border border-white/28 bg-white/12 shadow-[0_18px_50px_rgba(0,0,0,0.22)] backdrop-blur-md"
        style={{ boxShadow: `0 18px 60px ${accent}33` }}
      >
        <img
          src="/fox.png"
          alt="Little Artist fox mascot"
          className="h-[72px] w-[72px] object-contain"
          draggable={false}
        />
      </div>
      <div className="flex flex-col">
        <span className="text-[28px] font-extrabold uppercase tracking-[0.18em] text-white/56">
          Little Artist
        </span>
        <span className="text-[32px] font-bold text-white/90">
          Keep the masterpieces that matter.
        </span>
      </div>
    </div>
  );
}

function PaperNote({
  title,
  body,
  accent,
  style,
}: {
  title: string;
  body: string;
  accent: string;
  style?: CSSProperties;
}) {
  return (
    <div
      className="absolute rounded-[34px] border border-white/50 bg-[rgba(255,251,247,0.92)] p-8 text-[#3D3D3D] shadow-[0_20px_50px_rgba(18,12,9,0.18)]"
      style={style}
    >
      <div
        className="mb-4 inline-flex rounded-full px-4 py-2 text-[22px] font-extrabold uppercase tracking-[0.12em]"
        style={{ color: accent, backgroundColor: `${accent}1A` }}
      >
        {title}
      </div>
      <p className="max-w-[300px] text-[28px] font-bold leading-[1.2]">{body}</p>
    </div>
  );
}

function WaveCard({ accent }: { accent: string }) {
  return (
    <div className="absolute right-[110px] bottom-[360px] rounded-[34px] border border-white/18 bg-white/10 px-12 py-10 backdrop-blur-lg">
      <div className="mb-6 text-[24px] font-extrabold uppercase tracking-[0.16em] text-white/60">
        Voice memories
      </div>
      <div className="flex items-center gap-4">
        {Array.from({ length: 18 }, (_, index) => {
          const heights = [22, 54, 32, 74, 50, 28, 62, 88, 42];
          const height = heights[index % heights.length];
          return (
            <span
              // Decorative waveform bars.
              key={index}
              className="block w-3 rounded-full"
              style={{
                height,
                background: `linear-gradient(180deg, ${accent}, rgba(255,255,255,0.82))`,
              }}
            />
          );
        })}
      </div>
    </div>
  );
}

function FeaturePills({
  pills,
  accent,
  align = "left",
}: {
  pills: readonly string[];
  accent: string;
  align?: "left" | "center";
}) {
  return (
    <div
      className={`flex flex-wrap gap-4 ${align === "center" ? "justify-center" : "justify-start"}`}
    >
      {pills.map((pill) => (
        <span
          key={pill}
          className="rounded-full border border-white/22 bg-white/10 px-6 py-3 text-[24px] font-bold text-white/88 backdrop-blur-md"
          style={{ boxShadow: `0 0 0 1px ${accent}1F inset` }}
        >
          {pill}
        </span>
      ))}
    </div>
  );
}

function Doodle({
  accent,
  style,
}: {
  accent: string;
  style?: CSSProperties;
}) {
  return (
    <div
      aria-hidden
      className="absolute rounded-full border-[5px] border-dashed opacity-70"
      style={{
        borderColor: `${accent}66`,
        ...style,
      }}
    />
  );
}

function SlideCanvas({
  slide,
  index,
}: {
  slide: (typeof slides)[number];
  index: number;
}) {
  return (
    <section
      className="relative overflow-hidden text-white"
      style={{
        width: W,
        height: H,
        background: slide.backdrop,
      }}
    >
      <div
        className="absolute inset-0"
        style={{
          background:
            "linear-gradient(180deg, rgba(255,255,255,0.06), rgba(255,255,255,0) 18%), radial-gradient(circle at 20% 14%, rgba(255,255,255,0.08), transparent 16%)",
        }}
      />

      <div
        className="absolute -top-[120px] right-[60px] h-[440px] w-[440px] rounded-full blur-[90px]"
        style={{ backgroundColor: slide.accentSoft }}
      />
      <div
        className="absolute bottom-[-110px] left-[80px] h-[380px] w-[380px] rounded-full blur-[100px]"
        style={{ backgroundColor: `${slide.accent}18` }}
      />

      <Doodle
        accent={slide.accent}
        style={{ top: 150, right: 110, width: 190, height: 190, rotate: "8deg" }}
      />
      <Doodle
        accent={slide.accent}
        style={{ bottom: 240, left: 70, width: 140, height: 140, rotate: "-14deg" }}
      />

      <div className="absolute inset-0 p-[86px]">
        <div className="mb-10 flex items-start justify-between">
          <BrandLockup accent={slide.accent} />
          <div className="rounded-full border border-white/18 bg-white/10 px-6 py-4 text-[24px] font-extrabold uppercase tracking-[0.2em] text-white/68 backdrop-blur-lg">
            0{index + 1}
          </div>
        </div>

        {slide.layout === "hero" && (
          <>
            <div className="absolute left-[86px] top-[420px] max-w-[540px]">
              <div
                className="mb-8 inline-flex rounded-full px-6 py-3 text-[24px] font-extrabold uppercase tracking-[0.18em]"
                style={{ backgroundColor: `${slide.accent}24`, color: "#FFE6DC" }}
              >
                {slide.kicker}
              </div>
              <h1 className="text-[154px] font-black leading-[0.92] tracking-[-0.05em]">
                <span className="block">{slide.title[0]}</span>
                <span className="block" style={{ color: slide.accent }}>
                  {slide.title[1]}
                </span>
              </h1>
              <p className="mt-10 max-w-[480px] text-[40px] leading-[1.3] text-white/80">
                {slide.body}
              </p>
              <div className="mt-10">
                <FeaturePills pills={slide.pills} accent={slide.accent} />
              </div>
            </div>

            <PaperNote
              title="Why parents stay"
              body="One beautiful place for the piles, drawers, and fridge-door favorites."
              accent={slide.accent}
              style={{ right: 90, top: 338, rotate: "7deg" }}
            />

            <div className="absolute right-[40px] bottom-[-80px]">
              <Phone
                src={slide.screenshot}
                alt="Little Artist onboarding preserve screen"
                className="w-[700px] drop-shadow-[0_54px_90px_rgba(0,0,0,0.34)]"
                style={{ rotate: "-8deg" }}
              />
            </div>
          </>
        )}

        {slide.layout === "center" && (
          <>
            <div className="absolute inset-x-[120px] top-[330px] text-center">
              <div
                className="mb-8 inline-flex rounded-full px-6 py-3 text-[24px] font-extrabold uppercase tracking-[0.18em]"
                style={{ backgroundColor: `${slide.accent}20`, color: "#EDF7EA" }}
              >
                {slide.kicker}
              </div>
              <h1 className="text-[146px] font-black leading-[0.92] tracking-[-0.05em]">
                <span className="block">{slide.title[0]}</span>
                <span className="block" style={{ color: slide.accent }}>
                  {slide.title[1]}
                </span>
              </h1>
              <p className="mx-auto mt-10 max-w-[820px] text-[40px] leading-[1.3] text-white/80">
                {slide.body}
              </p>
            </div>

            <PaperNote
              title="Fast flow"
              body="Snap, save, and move on before the glitter spreads."
              accent={slide.accent}
              style={{ left: 74, top: 1080, rotate: "-10deg" }}
            />
            <PaperNote
              title="Built for real life"
              body="Quick enough for busy mornings and after-school chaos."
              accent={slide.accent}
              style={{ right: 78, top: 1180, rotate: "10deg" }}
            />

            <div className="absolute inset-x-0 bottom-[-120px] flex justify-center">
              <Phone
                src={slide.screenshot}
                alt="Little Artist onboarding capture screen"
                className="w-[780px] drop-shadow-[0_58px_90px_rgba(0,0,0,0.34)]"
              />
            </div>
          </>
        )}

        {slide.layout === "split-right" && (
          <>
            <div className="absolute left-[86px] top-[470px] max-w-[520px]">
              <div
                className="mb-8 inline-flex rounded-full px-6 py-3 text-[24px] font-extrabold uppercase tracking-[0.18em]"
                style={{ backgroundColor: `${slide.accent}22`, color: "#E7F4FD" }}
              >
                {slide.kicker}
              </div>
              <h1 className="text-[144px] font-black leading-[0.92] tracking-[-0.05em]">
                <span className="block">{slide.title[0]}</span>
                <span className="block" style={{ color: slide.accent }}>
                  {slide.title[1]}
                </span>
              </h1>
              <p className="mt-10 max-w-[480px] text-[40px] leading-[1.3] text-white/80">
                {slide.body}
              </p>
              <div className="mt-10">
                <FeaturePills pills={slide.pills} accent={slide.accent} />
              </div>
            </div>

            <div className="absolute right-[48px] bottom-[-20px]">
              <Phone
                src={slide.screenshot}
                alt="Little Artist onboarding captions screen"
                className="w-[650px] drop-shadow-[0_56px_92px_rgba(0,0,0,0.34)]"
                style={{ rotate: "5deg" }}
              />
            </div>

            <PaperNote
              title="Save the story"
              body="Remember what they made and what it meant that day."
              accent={slide.accent}
              style={{ left: 120, bottom: 300, rotate: "-7deg" }}
            />
          </>
        )}

        {slide.layout === "split-left" && (
          <>
            <div className="absolute left-[40px] bottom-[-20px]">
              <Phone
                src={slide.screenshot}
                alt="Little Artist onboarding voice note screen"
                className="w-[650px] drop-shadow-[0_56px_92px_rgba(0,0,0,0.34)]"
                style={{ rotate: "-6deg" }}
              />
            </div>

            <div className="absolute right-[90px] top-[520px] max-w-[520px]">
              <div
                className="mb-8 inline-flex rounded-full px-6 py-3 text-[24px] font-extrabold uppercase tracking-[0.18em]"
                style={{ backgroundColor: `${slide.accent}24`, color: "#F0EAFF" }}
              >
                {slide.kicker}
              </div>
              <h1 className="text-[144px] font-black leading-[0.92] tracking-[-0.05em]">
                <span className="block">{slide.title[0]}</span>
                <span className="block" style={{ color: slide.accent }}>
                  {slide.title[1]}
                </span>
              </h1>
              <p className="mt-10 max-w-[500px] text-[40px] leading-[1.3] text-white/80">
                {slide.body}
              </p>
              <div className="mt-10">
                <FeaturePills pills={slide.pills} accent={slide.accent} />
              </div>
            </div>

            <WaveCard accent={slide.accent} />
          </>
        )}

        {slide.layout === "celebrate" && (
          <>
            <div className="absolute left-[86px] top-[470px] max-w-[520px]">
              <div
                className="mb-8 inline-flex rounded-full px-6 py-3 text-[24px] font-extrabold uppercase tracking-[0.18em]"
                style={{ backgroundColor: `${slide.accent}24`, color: "#FFE8E5" }}
              >
                {slide.kicker}
              </div>
              <h1 className="text-[146px] font-black leading-[0.92] tracking-[-0.05em]">
                <span className="block">{slide.title[0]}</span>
                <span className="block" style={{ color: slide.accent }}>
                  {slide.title[1]}
                </span>
              </h1>
              <p className="mt-10 max-w-[490px] text-[40px] leading-[1.3] text-white/80">
                {slide.body}
              </p>
              <div className="mt-10">
                <FeaturePills pills={slide.pills} accent={slide.accent} />
              </div>
            </div>

            <PaperNote
              title="Feel close"
              body="Share a masterpiece the moment it lands on the fridge."
              accent={slide.accent}
              style={{ left: 90, bottom: 310, rotate: "-8deg" }}
            />

            <div className="absolute right-[42px] bottom-[-30px]">
              <Phone
                src={slide.screenshot}
                alt="Little Artist onboarding share screen"
                className="w-[650px] drop-shadow-[0_56px_92px_rgba(0,0,0,0.34)]"
                style={{ rotate: "6deg" }}
              />
            </div>
          </>
        )}
      </div>
    </section>
  );
}

function PreviewCard({
  slide,
  index,
}: {
  slide: (typeof slides)[number];
  index: number;
}) {
  const frameRef = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(0.24);

  useEffect(() => {
    const node = frameRef.current;
    if (!node) {
      return;
    }

    const updateScale = () => {
      setScale(node.clientWidth / W);
    };

    updateScale();

    const observer = new ResizeObserver(updateScale);
    observer.observe(node);

    return () => observer.disconnect();
  }, []);

  return (
    <article className="rounded-[36px] border border-white/10 bg-white/6 p-4 shadow-[0_24px_60px_rgba(0,0,0,0.22)] backdrop-blur-lg">
      <div className="mb-4 flex items-center justify-between px-3">
        <div>
          <div className="text-xs font-extrabold uppercase tracking-[0.24em] text-white/48">
            Slide 0{index + 1}
          </div>
          <div className="mt-1 text-lg font-bold text-white/88">{slide.title.join(" ")}</div>
        </div>
        <div
          className="rounded-full px-3 py-1 text-xs font-extrabold uppercase tracking-[0.22em]"
          style={{ backgroundColor: `${slide.accent}22`, color: slide.accent }}
        >
          {slide.slug}
        </div>
      </div>
      <div
        ref={frameRef}
        className="relative w-full overflow-hidden rounded-[28px]"
        style={{ aspectRatio: `${W}/${H}` }}
      >
        <div
          className="absolute left-0 top-0 origin-top-left"
          style={{
            width: W,
            height: H,
            transform: `scale(${scale})`,
          }}
        >
          <SlideCanvas slide={slide} index={index} />
        </div>
      </div>
    </article>
  );
}

export default function Home() {
  const exportRefs = useRef<(HTMLDivElement | null)[]>([]);
  const [busy, setBusy] = useState<string | null>(null);
  const [exportView, setExportView] = useState(false);

  useEffect(() => {
    setExportView(new URLSearchParams(window.location.search).get("view") === "export");
  }, []);

  async function captureSlide(node: HTMLDivElement) {
    await document.fonts.ready;
    await wait(100);

    node.style.left = "0px";
    node.style.opacity = "1";
    node.style.zIndex = "-1";

    const options = {
      width: W,
      height: H,
      pixelRatio: 1,
      cacheBust: true,
    };

    await toPng(node, options);
    const dataUrl = await toPng(node, options);

    node.style.left = "-9999px";
    node.style.opacity = "";
    node.style.zIndex = "";

    return dataUrl;
  }

  async function exportSingle(index: number) {
    const node = exportRefs.current[index];
    if (!node) {
      return;
    }

    setBusy(`Exporting slide ${index + 1}`);

    try {
      const baseDataUrl = await captureSlide(node);

      for (const size of SIZES) {
        const blob = await renderOpaqueBlob(
          baseDataUrl,
          size.w,
          size.h,
          slides[index].backgroundBase,
        );
        downloadBlob(
          blob,
          getExportFilename(index, slides[index].slug, size.w, size.h),
        );
        await wait(180);
      }
    } finally {
      setBusy(null);
    }
  }

  async function exportAll() {
    setBusy("Packaging ZIP export");

    try {
      const zip = new JSZip();
      const root = zip.folder(getArchiveName());
      if (!root) {
        throw new Error("Unable to create export archive.");
      }

      for (let index = 0; index < slides.length; index += 1) {
        const node = exportRefs.current[index];
        if (!node) {
          continue;
        }

        const baseDataUrl = await captureSlide(node);
        const slide = slides[index];

        for (const size of SIZES) {
          const blob = await renderOpaqueBlob(
            baseDataUrl,
            size.w,
            size.h,
            slide.backgroundBase,
          );
          root
            .folder(`${size.w}x${size.h}`)
            ?.file(getExportFilename(index, slide.slug, size.w, size.h), blob);
          await wait(180);
        }

        await wait(280);
      }

      const zipBlob = await zip.generateAsync({
        type: "blob",
        compression: "DEFLATE",
        compressionOptions: { level: 6 },
      });

      downloadBlob(zipBlob, `${getArchiveName()}.zip`);
    } finally {
      setBusy(null);
    }
  }

  if (exportView) {
    return (
      <main className="min-h-screen bg-[#140E0C] p-10">
        <div className="mx-auto flex w-fit flex-col gap-8">
          {slides.map((slide, index) => (
            <div
              key={slide.slug}
              data-export-slide={slide.slug}
              className="overflow-hidden rounded-[40px] shadow-[0_24px_60px_rgba(0,0,0,0.34)]"
            >
              <SlideCanvas slide={slide} index={index} />
            </div>
          ))}
        </div>
      </main>
    );
  }

  return (
    <>
      <main className="min-h-screen px-6 py-8 text-white md:px-10 xl:px-14">
        <div className="mx-auto max-w-[1560px]">
          <header className="mb-8 flex flex-col gap-6 rounded-[36px] border border-white/10 bg-white/8 p-6 shadow-[0_24px_80px_rgba(0,0,0,0.25)] backdrop-blur-lg md:flex-row md:items-center md:justify-between">
            <div className="max-w-[860px]">
              <div className="text-sm font-extrabold uppercase tracking-[0.24em] text-white/42">
                Little Artist App Store Set
              </div>
              <h1 className="mt-3 text-4xl font-black tracking-[-0.05em] text-white md:text-6xl">
                Warm, story-led screenshots built from the real onboarding captures.
              </h1>
              <p className="mt-4 max-w-[760px] text-base leading-7 text-white/70 md:text-lg">
                Source assets: the five 6.9-inch screenshots from Downloads, the fox
                mascot from the native iOS target, and the Little Artist coral/cream
                palette from the repo&apos;s brand tokens.
              </p>
              <p className="mt-3 max-w-[760px] text-sm leading-6 text-white/55 md:text-base">
                Export All downloads one ZIP package of opaque PNG screenshots,
                grouped into Apple-ready resolution folders for easier uploading.
              </p>
            </div>

            <div className="flex flex-wrap items-center gap-3">
              <button
                type="button"
                onClick={exportAll}
                disabled={busy !== null}
                className="rounded-full bg-[#F2784B] px-6 py-4 text-sm font-extrabold uppercase tracking-[0.18em] text-white shadow-[0_18px_40px_rgba(242,120,75,0.34)] transition hover:brightness-105 disabled:cursor-not-allowed disabled:opacity-70"
              >
                Export All ZIP
              </button>
              <a
                href="/?view=export"
                className="rounded-full border border-white/16 bg-white/8 px-6 py-4 text-sm font-extrabold uppercase tracking-[0.18em] text-white/82 transition hover:bg-white/12"
              >
                Open Export View
              </a>
              <div className="rounded-full border border-white/12 bg-black/18 px-5 py-4 text-sm font-bold text-white/70">
                {busy ?? "Ready to export"}
              </div>
            </div>
          </header>

          <section className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
            {slides.map((slide, index) => (
              <div key={slide.slug} className="space-y-3">
                <PreviewCard slide={slide} index={index} />
                <button
                  type="button"
                  onClick={() => exportSingle(index)}
                  disabled={busy !== null}
                  className="w-full rounded-full border border-white/14 bg-white/8 px-5 py-3 text-sm font-extrabold uppercase tracking-[0.18em] text-white/82 transition hover:bg-white/12 disabled:cursor-not-allowed disabled:opacity-70"
                >
                  Export Slide 0{index + 1} PNGs
                </button>
              </div>
            ))}
          </section>
        </div>
      </main>

      <div className="pointer-events-none absolute left-[-9999px] top-0">
        {slides.map((slide, index) => (
          <div
            key={slide.slug}
            ref={(node) => {
              exportRefs.current[index] = node;
            }}
            data-hidden-export={slide.slug}
            style={{
              position: "absolute",
              left: -9999,
              top: index * (H + 40),
              width: W,
              height: H,
              fontFamily: "var(--font-nunito), sans-serif",
            }}
          >
            <SlideCanvas slide={slide} index={index} />
          </div>
        ))}
      </div>
    </>
  );
}
