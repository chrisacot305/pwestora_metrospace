<?php
/**
 * includes/lease_checklist.php
 * Standard commercial-lease clauses reflected in common Philippine
 * practice (2-month security deposit, 5% annual escalation, 30-day
 * notice, etc.). These are GENERIC, common-practice terms — not legal
 * advice, and not tailored to any specific property or jurisdiction
 * nuance. Both parties should have a licensed attorney review the final
 * lease before signing anything based on this template.
 */
$LEASE_CHECKLIST_ITEMS = [
    'security_deposit' => [
        'label' => 'Security Deposit',
        'text'  => "A security deposit equivalent to two (2) months' rent will be collected and held. "
                 . "It is refundable within 30 days of lease-end, less any deductions for damages or unpaid obligations.",
    ],
    'rent_escalation' => [
        'label' => 'Rent Escalation',
        'text'  => "Monthly rent may increase by up to five percent (5%) upon each annual renewal, "
                 . "consistent with standard commercial leasing practice.",
    ],
    'use_of_premises' => [
        'label' => 'Use of Premises',
        'text'  => "The leased premises will be used solely for the business purpose stated in the tenant's application, "
                 . "and not for any illegal or unauthorized activity.",
    ],
    'maintenance_responsibility' => [
        'label' => 'Maintenance Responsibility',
        'text'  => "Structural and major-system repairs are the lessor's responsibility. "
                 . "Interior fixtures, fittings, and day-to-day upkeep are the tenant's responsibility.",
    ],
    'no_sublease' => [
        'label' => 'No Subleasing',
        'text'  => "The tenant will not sublease, assign, or transfer the lease to a third party without the lessor's prior written consent.",
    ],
    'termination_notice' => [
        'label' => 'Termination Notice',
        'text'  => "At least thirty (30) days' written notice is required before vacating the premises or terminating the lease early.",
    ],
    'insurance' => [
        'label' => 'Insurance',
        'text'  => "The tenant is responsible for insuring their own business property, inventory, and equipment within the premises.",
    ],
    'compliance' => [
        'label' => 'Legal Compliance',
        'text'  => "The tenant will comply with all applicable national and local laws — including business permits, "
                 . "fire safety, and zoning regulations — for the duration of the lease.",
    ],
];
