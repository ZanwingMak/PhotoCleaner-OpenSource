const legalLanguages = ["en", "zh", "ja", "ko"];

/** 根据保存设置与浏览器首选项选择法律页面语言 */
function getLegalLanguage() {
  const savedLanguage = window.localStorage.getItem("rollKeepSiteLanguage")
    || window.localStorage.getItem("photoCleanerSiteLanguage");
  if (legalLanguages.includes(savedLanguage)) return savedLanguage;

  const browserLanguage = (window.navigator.language || "en").toLowerCase();
  if (browserLanguage.startsWith("zh")) return "zh";
  if (browserLanguage.startsWith("ja")) return "ja";
  if (browserLanguage.startsWith("ko")) return "ko";
  return "en";
}

/** 切换法律页面语言并更新可访问状态 */
function setLegalLanguage(language) {
  const activeLanguage = legalLanguages.includes(language) ? language : "en";
  document.documentElement.lang = activeLanguage === "zh" ? "zh-Hans" : activeLanguage;

  document.querySelectorAll("[data-legal-lang]").forEach((section) => {
    const isActive = section.getAttribute("data-legal-lang") === activeLanguage;
    section.hidden = !isActive;
  });

  document.querySelectorAll("[data-lang]").forEach((button) => {
    const isActive = button.getAttribute("data-lang") === activeLanguage;
    button.classList.toggle("is-active", isActive);
    button.setAttribute("aria-pressed", String(isActive));
  });

  window.localStorage.setItem("rollKeepSiteLanguage", activeLanguage);
}

/** 初始化法律页面语言切换器 */
function initLegalPage() {
  document.querySelectorAll("[data-lang]").forEach((button) => {
    button.addEventListener("click", () => setLegalLanguage(button.getAttribute("data-lang")));
  });
  setLegalLanguage(getLegalLanguage());
}

initLegalPage();
