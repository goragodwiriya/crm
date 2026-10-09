function initCrmPipeline(element, data) {
  const updateCounters = () => {
    document.querySelectorAll('.kanban-column').forEach(column => {
      const count = column.querySelectorAll('.kanban-card').length;
      const counter = column.querySelector('.column-count');
      if (counter) counter.textContent = count;
    });
  };

  // Update kanban column counters when cards are moved
  document.addEventListener('sortable:end', updateCounters);

  // Return cleanup function
  return () => {
    document.removeEventListener('sortable:end', updateCounters);
  };
}

function formatDealStage(cell, rawValue, rowData, attributes) {
  const stages = ['qualified', 'won', 'negotiation', 'lost', 'lead', 'proposal'];
  cell.innerHTML = `<span class="status${stages.indexOf(rawValue)}">${Utils.string.humanize(rawValue)}</span>`;
}

function formatCustomerStatus(cell, rawValue, rowData, attributes) {
  const statuses = ['lead', 'prospect', 'customer', 'inactive', 'churned'];
  const humanized = Utils.string.humanize(rawValue);
  cell.innerHTML = `<span class="status${statuses.indexOf(rawValue)}" data-i18n="${humanized}">${Now.translate(humanized)}</span>`;
}

function formatCustomerSource(cell, rawValue, rowData, attributes) {
  const icons = {
    website: 'icon-world',
    referral: 'icon-link',
    cold_call: 'icon-phone',
    advertisement: 'icon-ads',
    trade_show: 'icon-product',
    social_media: 'icon-share',
    other: 'icon-file'
  };
  const humanized = Utils.string.humanize(rawValue);
  const icon = icons[rawValue] ?? 'icon-file';
  cell.innerHTML = `<span class="${icon}" title="${Now.translate(humanized)}"></span>`;
}

function formatCampaignStatus(cell, rawValue, rowData, attributes) {
  const statuses = ['scheduled', 'paused', 'active', 'draft', 'cancelled', 'completed'];
  const humanized = Utils.string.humanize(rawValue);
  cell.innerHTML = `<span class="status${statuses.indexOf(rawValue)}" data-i18n="${humanized}">${Now.translate(humanized)}</span>`;
}

function formatCampaignIcon(cell, rawValue, rowData, attributes) {
  const icons = {
    email: 'icon-email',
    social: 'icon-share',
    event: 'icon-event',
    webinar: 'icon-published1',
    advertisement: 'icon-ads',
    other: 'icon-file'
  };
  const humanized = Utils.string.humanize(rawValue);
  const icon = icons[rawValue] ?? 'icon-file';
  cell.innerHTML = `<span class="${icon}" title="${Now.translate(humanized)}"></span>`;
}

function formatActivityStatus(cell, rawValue, rowData, attributes) {
  const statuses = {
    scheduled: 'status0',
    completed: 'status1',
    cancelled: 'status3',
    no_show: 'status4'
  };
  const humanized = Utils.string.humanize(rawValue);
  const status = statuses[rawValue] ?? statuses.cancelled;
  cell.innerHTML = `<span class="${status}" data-i18n="${humanized}">${Now.translate(humanized)}</span>`;
}

function formatActivityPriority(cell, rawValue, rowData, attributes) {
  const statuses = {
    low: 'status3',
    medium: 'status1',
    high: 'status4'
  };
  const humanized = Utils.string.humanize(rawValue);
  const status = statuses[rawValue] ?? statuses.low;
  cell.innerHTML = `<span class="${status}" data-i18n="${humanized}">${Now.translate(humanized)}</span>`;
}

function formatActivityIcon(cell, rawValue, rowData, attributes) {
  const icons = {
    call: 'icon-phone',
    meeting: 'icon-event',
    email: 'icon-email',
    task: 'icon-list',
    note: 'icon-file',
    lunch: 'icon-food',
    demo: 'icon-published1',
    follow_up: 'icon-clock'
  };
  const humanized = Utils.string.humanize(rawValue);
  const icon = icons[rawValue] ?? 'icon-list';
  cell.innerHTML = `<span class="${icon}" title="${Now.translate(humanized)}"></span>`;
}

// Register Routes for CRM Module via EventManager
EventManager.on('router:initialized', () => {
  RouterManager.register('/', {
    template: '/crm/dashboard.html',
    title: '{LNG_Dashboard}',
    requireAuth: true
  });
  RouterManager.register('/crm-pipeline', {
    template: '/crm/pipeline.html',
    title: '{LNG_Sales Pipeline}',
    requireAuth: true
  });
  RouterManager.register('/crm-deals', {
    template: '/crm/deals.html',
    title: '{LNG_Deals}',
    requireAuth: true
  });
  RouterManager.register('/crm-deal', {
    template: '/crm/deal.html',
    title: '{LNG_Deal}',
    menuPath: '/crm-deals',
    requireAuth: true
  });
  RouterManager.register('/crm-customers', {
    template: '/crm/customers.html',
    title: '{LNG_Customers}',
    requireAuth: true
  });
  RouterManager.register('/crm-customer', {
    template: '/crm/customer.html',
    title: '{LNG_Customer}',
    menuPath: '/crm-customers',
    requireAuth: true
  });
  RouterManager.register('/crm-contacts', {
    template: '/crm/contacts.html',
    title: '{LNG_Contacts}',
    requireAuth: true
  });
  RouterManager.register('/crm-contact', {
    template: '/crm/contact.html',
    title: '{LNG_Contact}',
    menuPath: '/crm-contacts',
    requireAuth: true
  });
  RouterManager.register('/crm-activities', {
    template: '/crm/activities.html',
    title: '{LNG_Activities}',
    requireAuth: true
  });
  RouterManager.register('/crm-activity', {
    template: '/crm/activity.html',
    title: '{LNG_Activity}',
    menuPath: '/crm-activities',
    requireAuth: true
  });
  RouterManager.register('/crm-campaigns', {
    template: '/crm/campaigns.html',
    title: '{LNG_Campaigns}',
    requireAuth: true
  });
  RouterManager.register('/crm-campaign', {
    template: '/crm/campaign.html',
    title: '{LNG_Campaign}',
    menuPath: '/crm-campaigns',
    requireAuth: true
  });
});
