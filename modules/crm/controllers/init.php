<?php
/**
 * @filesource modules/crm/controllers/init.php
 *
 * @copyright 2026 Goragod.com
 * @license https://www.kotchasan.com/license/
 */

namespace Crm\Init;

/**
 * API Authentication Controller
 *
 * Handles user authentication endpoints with production-grade security
 *
 * @author Goragod Wiriya <admin@goragod.com>
 *
 * @since 1.0
 */
class Controller extends \Gcms\Controller
{
    /**
     * Get menu data
     *
     * @param array $menus
     * @param array $params
     *
     * @return array
     */
    public static function initMenus($menus, $params)
    {
        $crm_menu = [
            [
                'title' => 'CRM',
                'icon' => 'icon-support',
                'children' => [
                    [
                        'title' => 'Pipeline',
                        'url' => '/crm-pipeline',
                        'icon' => 'icon-grid'
                    ],
                    [
                        'title' => 'Deals',
                        'url' => '/crm-deals',
                        'icon' => 'icon-wallet'
                    ],
                    [
                        'title' => 'Customers',
                        'url' => '/crm-customers',
                        'icon' => 'icon-customer'
                    ],
                    [
                        'title' => 'Contacts',
                        'url' => '/crm-contacts',
                        'icon' => 'icon-phone'
                    ],
                    [
                        'title' => 'Activities',
                        'url' => '/crm-activities',
                        'icon' => 'icon-event'
                    ],
                    [
                        'title' => 'Campaigns',
                        'url' => '/crm-campaigns',
                        'icon' => 'icon-flag'
                    ]
                ]
            ]
        ];

        // Insert product menus after Dashboard (position 0)
        $menus = parent::insertMenuAfter($menus, $crm_menu, 0);

        // return menus
        return $menus;
    }

    /**
     * Get permission data
     *
     * @param array $permissions
     * @param array $params
     *
     * @return array
     */
    public static function initPermission($permissions, $params)
    {
        // Add CRM permissions
        $permissions[] = ['value' => 'can_manage_crm', 'text' => '{LNG_Can manage} CRM'];
        $permissions[] = ['value' => 'can_view_crm', 'text' => '{LNG_Can view} CRM'];

        // return permissions
        return $permissions;
    }
}
