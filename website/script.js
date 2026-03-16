// ===== 语言切换 =====
let currentLang = 'zh';

function toggleLang() {
  currentLang = currentLang === 'zh' ? 'en' : 'zh';
  applyLang();
  document.getElementById('langToggle').textContent = currentLang === 'zh' ? 'EN' : '中';
  document.documentElement.lang = currentLang === 'zh' ? 'zh-Hans' : 'en';
}

function applyLang() {
  const attr = 'data-' + currentLang;
  document.querySelectorAll('[data-zh]').forEach(el => {
    const text = el.getAttribute(attr);
    if (!text) return;
    // 支持 innerHTML（含 <br>）
    if (text.includes('<br>') || text.includes('<')) {
      el.innerHTML = text;
    } else {
      el.textContent = text;
    }
  });
  // 切换隐私/条款链接语言参数
  const suffix = currentLang === 'en' ? '?lang=en' : '';
  const lp = document.getElementById('linkPrivacy');
  const lt = document.getElementById('linkTerms');
  if (lp) lp.href = 'privacy.html' + suffix;
  if (lt) lt.href = 'terms.html' + suffix;
  // 切换 Hero 截图
  const heroImg = document.getElementById('screenshotMain');
  if (heroImg) {
    const src = heroImg.getAttribute('data-src-' + currentLang);
    if (src) heroImg.src = src;
  }
  // 更新页面 title
  document.title = currentLang === 'zh'
    ? 'AI跑步教练 — 你的私人AI跑步教练'
    : 'AI Running Coach — Your Personal AI Running Coach';
}

// ===== 滚动显示动画 =====
function initReveal() {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry, i) => {
      if (entry.isIntersecting) {
        // 同组元素依次延迟出现
        const siblings = entry.target.parentElement.querySelectorAll('.reveal');
        let delay = 0;
        siblings.forEach((el, idx) => {
          if (el === entry.target) delay = idx * 80;
        });
        setTimeout(() => {
          entry.target.classList.add('visible');
        }, delay);
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.1, rootMargin: '0px 0px -40px 0px' });

  document.querySelectorAll('.reveal').forEach(el => observer.observe(el));
}

// ===== 导航栏滚动样式 =====
function initNavbar() {
  const navbar = document.querySelector('.navbar');
  window.addEventListener('scroll', () => {
    if (window.scrollY > 10) {
      navbar.style.background = 'rgba(10,10,10,0.95)';
    } else {
      navbar.style.background = 'rgba(10,10,10,0.85)';
    }
  }, { passive: true });
}

// ===== 截图占位（无图片时显示渐变背景）=====
function initScreenshots() {
  document.querySelectorAll('.screenshot').forEach(img => {
    img.addEventListener('error', () => {
      const parent = img.parentElement;
      img.style.display = 'none';
      // 显示占位内容
      const placeholder = document.createElement('div');
      placeholder.style.cssText = `
        width:100%; height:100%;
        background: linear-gradient(160deg, #1A1A2E, #0F3460, #533483);
        display:flex; flex-direction:column;
        align-items:center; justify-content:center;
        gap:12px; color:rgba(255,255,255,0.6);
        font-size:13px;
      `;
      placeholder.innerHTML = `<span style="font-size:48px">🏃</span><span>截图加载中</span>`;
      parent.appendChild(placeholder);
    });
  });
}

// ===== 初始化 =====
document.addEventListener('DOMContentLoaded', () => {
  initReveal();
  initNavbar();
  initScreenshots();
});
