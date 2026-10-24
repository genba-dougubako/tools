// 共通の絵のパーツ(SVG 文字列)
const hazardDefs = `
  <pattern id="hazard" width="60" height="60" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
    <rect width="60" height="60" fill="#ffc21a"/><rect width="30" height="60" fill="#1b1b1f"/>
  </pattern>
  <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
    <feGaussianBlur stdDeviation="8" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
  </filter>
  <linearGradient id="steel" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#8a9099"/><stop offset="1" stop-color="#3c4048"/>
  </linearGradient>
  <linearGradient id="carRed" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#ff4a3d"/><stop offset="1" stop-color="#a3120c"/>
  </linearGradient>`;

// 潰れた車(原点 = 車の底の中央、幅 480 基準)
const crushedCar = `
  <g>
    <ellipse cx="-150" cy="-14" rx="52" ry="20" fill="#18181b"/>
    <ellipse cx="150" cy="-14" rx="52" ry="20" fill="#18181b"/>
    <path d="M-240 -18 L-232 -62 L-120 -74 L-70 -98 L80 -100 L140 -76 L236 -66 L242 -20 Z" fill="url(#carRed)" stroke="#5a0805" stroke-width="6"/>
    <path d="M-60 -92 L70 -94 L110 -78 L-100 -76 Z" fill="#9ad3f0" opacity=".85"/>
    <path d="M-200 -44 L-140 -40 M30 -60 L90 -50 M150 -48 L210 -40" stroke="#5a0805" stroke-width="6" stroke-linecap="round"/>
    <rect x="-246" y="-34" width="18" height="14" fill="#ffe9a6"/>
    <rect x="228" y="-36" width="18" height="14" fill="#ff3b3b"/>
  </g>`;

function spark(x, y, r, rot, color) {
  const pts = [];
  for (let i = 0; i < 8; i++) {
    const a = (Math.PI / 4) * i;
    const rr = i % 2 === 0 ? r : r * 0.35;
    pts.push(`${(Math.cos(a) * rr).toFixed(1)},${(Math.sin(a) * rr).toFixed(1)}`);
  }
  return `<polygon points="${pts.join(" ")}" fill="${color}" transform="translate(${x} ${y}) rotate(${rot})"/>`;
}

// 右向きの飛行機(原点 = 機体中央、長さ約 300)
const plane = `
  <g>
    <path d="M-150 -14 Q-160 0 -150 14 L120 18 Q160 14 170 0 Q160 -14 120 -18 Z" fill="#f4f6fa" stroke="#22324a" stroke-width="6"/>
    <path d="M-20 -10 L-70 -120 L-30 -120 L50 -10 Z" fill="#2f6fdb" stroke="#22324a" stroke-width="6"/>
    <path d="M-20 10 L-60 90 L-25 90 L45 10 Z" fill="#2f6fdb" stroke="#22324a" stroke-width="6"/>
    <path d="M-150 -10 L-185 -70 L-160 -70 L-110 -12 Z" fill="#e8402f" stroke="#22324a" stroke-width="6"/>
    <path d="M95 -14 Q130 -12 150 -4 L95 -4 Z" fill="#9ad3f0"/>
  </g>`;

function ring(cx, cy, rx, ry, width) {
  return `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="none" stroke="#3be7ff" stroke-width="${width}" filter="url(#glow)"/>
          <ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="none" stroke="#e8fdff" stroke-width="${width * 0.3}"/>`;
}

function coin(x, y, r) {
  return `<g transform="translate(${x} ${y})"><circle r="${r}" fill="#ffcf2e" stroke="#9a6a00" stroke-width="${r * 0.14}"/>
          <circle r="${r * 0.62}" fill="none" stroke="#fff3b0" stroke-width="${r * 0.12}"/></g>`;
}
