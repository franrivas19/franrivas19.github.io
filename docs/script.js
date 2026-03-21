// ========================
// OS DETECTION
// ========================

function detectOS() {
    const ua = navigator.userAgent;
    const isAndroid = /Android/.test(ua);
    const isLinux = /Linux/.test(ua) && !/Android/.test(ua);
    const isMobile = /Mobile|iPhone|iPad/.test(ua);
    
    const androidOption = document.getElementById('android-option');
    const linuxOption = document.getElementById('linux-option');
    const osDetector = document.querySelector('.os-detector');
    
    // Reset all display
    if (androidOption) androidOption.style.display = 'none';
    if (linuxOption) linuxOption.style.display = 'none';
    
    // Show appropriate download option
    if (isAndroid || (isMobile && !isLinux)) {
        if (androidOption) {
            androidOption.style.display = 'block';
            androidOption.classList.add('animate-in');
        }
        if (osDetector) osDetector.innerHTML = '<p>✅ Android detectado - Descarga optimizada para ti</p>';
    } else if (isLinux) {
        if (linuxOption) {
            linuxOption.style.display = 'block';
            linuxOption.classList.add('animate-in');
        }
        if (osDetector) osDetector.innerHTML = '<p>✅ Linux detectado - Descarga optimizada para ti</p>';
    } else {
        // Show both for other systems
        if (androidOption) androidOption.style.display = 'block';
        if (linuxOption) linuxOption.style.display = 'block';
        if (osDetector) osDetector.innerHTML = '<p>Selecciona tu sistema operativo</p>';
    }
}

// ========================
// SMOOTH SCROLL
// ========================

document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// ========================
// INTERSECTION OBSERVER FOR ANIMATIONS
// ========================

const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver(function(entries) {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('in-view');
            observer.unobserve(entry.target);
        }
    });
}, observerOptions);

// Observe all animated elements
document.querySelectorAll('.feature-card, .download-option, .feature-box').forEach(el => {
    observer.observe(el);
});

// ========================
// PARALLAX EFFECT
// ========================

window.addEventListener('scroll', () => {
    const scrolled = window.pageYOffset;
    const parallaxElements = document.querySelectorAll('.hero-background::before, .hero-background::after');
    
    document.querySelector('.hero-background')?.style.setProperty(
        '--scroll',
        scrolled * 0.5 + 'px'
    );
});

// ========================
// NAVBAR HIDE/SHOW ON SCROLL
// ========================

let lastScrollTop = 0;
const navbar = document.querySelector('.navbar');

window.addEventListener('scroll', () => {
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
    
    if (scrollTop > 100) {
        if (scrollTop > lastScrollTop) {
            // Scrolling down
            navbar.style.transform = 'translateY(-100%)';
        } else {
            // Scrolling up
            navbar.style.transform = 'translateY(0)';
        }
    }
    
    lastScrollTop = scrollTop <= 0 ? 0 : scrollTop;
});

// ========================
// BUTTON RIPPLE EFFECT
// ========================

document.querySelectorAll('.btn').forEach(button => {
    button.addEventListener('click', function(e) {
        const ripple = document.createElement('span');
        const rect = this.getBoundingClientRect();
        const size = Math.max(rect.width, rect.height);
        const x = e.clientX - rect.left - size / 2;
        const y = e.clientY - rect.top - size / 2;
        
        ripple.style.width = ripple.style.height = size + 'px';
        ripple.style.left = x + 'px';
        ripple.style.top = y + 'px';
        ripple.classList.add('ripple');
        
        this.appendChild(ripple);
        
        setTimeout(() => ripple.remove(), 600);
    });
});

// ========================
// COUNTER ANIMATION
// ========================

function animateCounters() {
    const stats = document.querySelectorAll('.stat-number');
    
    stats.forEach(stat => {
        const finalValue = stat.textContent;
        let currentValue = 0;
        
        const observer = new IntersectionObserver(entries => {
            entries.forEach(entry => {
                if (entry.isIntersecting && !stat.dataset.animated) {
                    stat.dataset.animated = 'true';
                    
                    if (finalValue === '0') {
                        stat.textContent = '0';
                    } else if (finalValue === '∞') {
                        stat.textContent = '∞';
                    } else if (finalValue === '100%') {
                        let percent = 0;
                        const interval = setInterval(() => {
                            percent += Math.floor(Math.random() * 20) + 5;
                            if (percent >= 100) {
                                percent = 100;
                                clearInterval(interval);
                            }
                            stat.textContent = percent + '%';
                        }, 50);
                    }
                }
            });
        }, { threshold: 0.5 });
        
        observer.observe(stat);
    });
}

animateCounters();

// ========================
// SCROLL-TO-TOP BUTTON
// ========================

const scrollToTopBtn = document.createElement('button');
scrollToTopBtn.innerHTML = '↑';
scrollToTopBtn.className = 'scroll-to-top';
scrollToTopBtn.style.cssText = `
    position: fixed;
    bottom: 30px;
    right: 30px;
    width: 50px;
    height: 50px;
    border-radius: 50%;
    background: linear-gradient(135deg, #2563EB, #3B82F6);
    color: white;
    border: none;
    cursor: pointer;
    font-size: 24px;
    font-weight: bold;
    opacity: 0;
    transition: all 0.3s ease;
    z-index: 999;
    box-shadow: 0 8px 24px rgba(37, 99, 235, 0.3);
`;

document.body.appendChild(scrollToTopBtn);

window.addEventListener('scroll', () => {
    if (window.pageYOffset > 300) {
        scrollToTopBtn.style.opacity = '1';
        scrollToTopBtn.style.pointerEvents = 'auto';
    } else {
        scrollToTopBtn.style.opacity = '0';
        scrollToTopBtn.style.pointerEvents = 'none';
    }
});

scrollToTopBtn.addEventListener('click', () => {
    window.scrollTo({
        top: 0,
        behavior: 'smooth'
    });
});

scrollToTopBtn.addEventListener('mouseenter', function() {
    this.style.transform = 'scale(1.1)';
});

scrollToTopBtn.addEventListener('mouseleave', function() {
    this.style.transform = 'scale(1)';
});

// ========================
// ANIMATION ON LOAD
// ========================

window.addEventListener('load', () => {
    detectOS();
    document.body.classList.add('loaded');
});

// ========================
// CURSOR FOLLOW EFFECT (OPTIONAL)
// ========================

document.addEventListener('mousemove', (e) => {
    const { clientX, clientY } = e;
    
    document.querySelectorAll('.feature-card').forEach(card => {
        const rect = card.getBoundingClientRect();
        const cardCenterX = rect.left + rect.width / 2;
        const cardCenterY = rect.top + rect.height / 2;
        
        const angleX = (clientY - cardCenterY) * 0.05;
        const angleY = (clientX - cardCenterX) * -0.05;
        
        if (window.innerWidth > 768) {
            card.style.transform = `perspective(1000px) rotateX(${angleX}deg) rotateY(${angleY}deg)`;
        }
    });
});

// Reset transform on mouse leave
document.addEventListener('mouseleave', () => {
    document.querySelectorAll('.feature-card').forEach(card => {
        card.style.transform = 'perspective(1000px) rotateX(0) rotateY(0)';
    });
});

// ========================
// DOWNLOAD LINK HANDLERS
// ========================

// Update these with actual download links
document.querySelectorAll('.btn-download').forEach(btn => {
    btn.addEventListener('click', function(e) {
        const platform = this.closest('.download-option');
        if (platform) {
            const isAndroid = platform.id === 'android-option';
            const isLinux = platform.id === 'linux-option';
            
            if (isAndroid) {
                // Replace with actual Android APK download link
                console.log('Starting Android download...');
                window.location.href = 'https://your-app-url/download/gambeta.apk';
            } else if (isLinux) {
                // Replace with actual Linux download link
                console.log('Starting Linux download...');
                window.location.href = 'https://your-app-url/download/gambeta-linux';
            } else {
                // Web app link
                window.location.href = '/app';
            }
        }
    });
});

// ========================
// PERFORMANCE: Lazy loading images (if added later)
// ========================

if ('IntersectionObserver' in window) {
    const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src;
                img.classList.add('loaded');
                observer.unobserve(img);
            }
        });
    });

    document.querySelectorAll('img[data-src]').forEach(img => imageObserver.observe(img));
}

// ========================
// TOUCH SUPPORT FOR MOBILE
// ========================

let touchStartY = 0;

document.addEventListener('touchstart', (e) => {
    touchStartY = e.touches[0].clientY;
});

document.addEventListener('touchmove', (e) => {
    const touchEndY = e.touches[0].clientY;
    
    if (touchEndY > touchStartY + 100) {
        // Swipe down
        navbar.style.transform = 'translateY(0)';
    } else if (touchEndY < touchStartY - 100) {
        // Swipe up
        navbar.style.transform = 'translateY(-100%)';
    }
});

console.log('🚀 Gambeta Landing Page Loaded - All systems ready!');
